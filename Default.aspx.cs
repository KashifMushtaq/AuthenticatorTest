
/*
 Copyright (©) 2023 Kashif Mushtaq
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

using System;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.UI;

namespace AuthenticatorTest
{
    public partial class _Default : Page
    {

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                generateQRCode();
            }
        }




        /// <summary>
        /// Converts Hex string to Unsigned Bytes (0 to 256)
        /// </summary>
        /// <param name="hexStr"></param>
        /// <returns></returns>
        public Byte[] HexToByte(string hexStr)
        {
            byte[] bArray = new byte[hexStr.Length / 2];
            for (int i = 0; i < (hexStr.Length / 2); i++)
            {
                byte firstNibble = Byte.Parse(hexStr.Substring((2 * i), 1), System.Globalization.NumberStyles.HexNumber); // [x,y)
                byte secondNibble = Byte.Parse(hexStr.Substring((2 * i) + 1, 1), System.Globalization.NumberStyles.HexNumber);
                int finalByte = (secondNibble) | (firstNibble << 4); // bit-operations only with numbers, not bytes.
                bArray[i] = (byte)finalByte;
            }
            return bArray;
        }

        /// <summary>
        /// Generates GUID as a string and remove brackets
        /// </summary>
        /// <returns></returns>
        public string getNewId()
        {
            string sR = Guid.NewGuid().ToString().ToUpper();
            sR = sR.Replace("{", "");
            sR = sR.Replace("}", "");
            return sR;
        }

        /// <summary>
        /// Generates the QR code for authenticator as a base64 encoded svg image
        /// You must use something like
        /// <img runat = "server" id="qrCode" name="qrCode" src="javascript:" alt="Scan this QR code with your mobile application" style="height:300px;width:300px"/>
        /// </summary>
        private void generateQRCode()
        {
            //create new key based on hash to be used
            //string seed = getNewId() + getNewId();
            //seed = seed.Replace("-", "");
            //seed = seed.Substring(0, 40);

            string seed = "F7675FB111CF4B5EB2FAE36B5BDC7B61BF4199E3";
            byte[] byteSeed = HexToByte(seed);


            //Must save this seed to be able to validate the TOTP
            var KeyString = Base32.ToBase32String(byteSeed);

            string orgDomain = "elogic.synology.me";
            string orgName = "eLogic Builders Inc.";
            string userUPN = "test" + '@' + orgDomain;

            const string AuthenticatorUriFormat = "otpauth://totp/{0}:{1}?secret={2}&issuer={0}&algorithm=SHA1&digits=6&period=30";

            string tokenURI = string.Format(
                AuthenticatorUriFormat,
                HttpUtility.UrlEncode(orgDomain),
                HttpUtility.UrlEncode(userUPN),
                KeyString);


            var qr = Net.Codecrete.QrCodeGenerator.QrCode.EncodeText(tokenURI, Net.Codecrete.QrCodeGenerator.QrCode.Ecc.High);

            string base64EncodedImage = Convert.ToBase64String(Encoding.UTF8.GetBytes(qr.ToSvgString(4)));

            string imageSrc = "data:image/svg+xml;base64," + base64EncodedImage;

            //Assign image here in your ASP application
            this.qrCode.Src = imageSrc;
        }

        bool CheckTimeBasedOTP_Rfc6238(byte[] byteSeed, string incomingOTP)
        {
            bool bR = false;
            int IntIncomingCode = int.Parse(incomingOTP);

            var hash = new HMACSHA1(byteSeed);
            var unixTimestamp = Convert.ToInt64(Math.Round((DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0)).TotalSeconds));
            var timestep = Convert.ToInt64(unixTimestamp / 30);
            // Allow codes from 90s in each direction (we could make this configurable?)
            for (long i = -1; i <= 1; i++)
            {
                var expectedCode = Rfc6238AuthenticationService.ComputeTotp(hash, (ulong)(timestep + i), modifier: null);
                if (expectedCode == IntIncomingCode)
                {
                    bR = true;
                    break;
                }
            }

            return bR;
        }

        protected void Button_Test_Click(object sender, EventArgs e)
        {
            string seed = "F7675FB111CF4B5EB2FAE36B5BDC7B61BF4199E3";
            byte[] byteSeed = HexToByte(seed);

            string incomingOTP = this.textBox_TOTP.Text;

            if (string.IsNullOrEmpty(incomingOTP))
            {
                this.LabelResult.Text = "Must enter 6 digits TOTP generated by authenticator";
                return;
            }

            string LastTOTP = Session["LastTOTP"] == null ? string.Empty : Session["LastTOTP"] as string;

            if (LastTOTP.Equals(incomingOTP))
            {
                this.LabelResult.Text = "Must test next TOTP generated by authenticator";
                return;
            }
            else
            {
                Session["LastTOTP"] = incomingOTP;
            }

            if (CheckTimeBasedOTP_Rfc6238(byteSeed, incomingOTP))
            {
                this.LabelResult.Text = string.Format("TOTP [{0}] validation successful", incomingOTP);
            }
            else
            {
                this.LabelResult.Text = string.Format("TOTP [{0}] validation failed", incomingOTP);
            }
        }
    }
}