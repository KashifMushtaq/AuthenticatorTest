<%@ Page Title="About" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="About.aspx.cs" Inherits="AuthenticatorTest.About" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main aria-labelledby="title">
        <h2 id="title"><%: Title %>.</h2>
<p style="text-align: center"><img src="images/authenticator.jpg" style="width: 400px; height: 447px" /></p>

<h2>Introduction</h2>

<p>A time-based, One-time Password Algorithm (<a href="https://datatracker.ietf.org/doc/html/rfc6238">RFC-6238</a>, TOTP - HMAC-based One-time Password Algorithm) based token, implemented by e.g. Microsoft or Google Authenticator mobile applications. Mobile application allows you to register your account with Microsoft / Google or any other TOTP authenticator application (via a specially generated QR code). After successful registration, the authenticator application will generate a new code every 30 seconds which could be used to implement MFA based sign-in. To make it a complete MFA, a PIN is added as a prefix to the application generated code. The sign-in password or some call it Passcode will be the PIN + Code.</p>

<h2>Background</h2>

<p>To secure access to any C#, Java or C++ (Windows or Linux) web or normal application, MFA is a best and easy option without creating a custom mobile application of your own. It completes the scenario, that something you know and something you have.&nbsp;&nbsp;Here something you know is your PIN, and something you have is your mobile app and your bio-matric features forced by the authenticator mobile applications like <a href="https://www.microsoft.com/en-ca/security/mobile-authenticator-app">Microsoft Authenticator</a>.</p>

<h2>Registration of the QR Code</h2>

<p>The authenticator application (Microsoft and Google) follows a standard. Though, only Google defines the <a href="https://github.com/google/google-authenticator/wiki/Key-Uri-Format">URI and parameters</a> required to register an account with the Authenticator Application.</p>

<p>The first step logically is the ability to generate the QR code to register the required user with the authenticator application. The magic ingredient here is the TOTP seed, Company / Web Application user belongs to and User&#39;s UPN or email address.</p>

<p>The code below generates a seed using GUID (I use GUID because there is&nbsp;1 in 2 billion chance that same GUID will ever be regenerated):</p>

<pre lang="cs">
/**
* Converts Hex string to Unsigned Bytes (0 to 256)
*/
public static Byte[] HexToByte(string hexStr)
{
&nbsp; &nbsp; byte[] bArray = new byte[hexStr.Length / 2];
&nbsp; &nbsp; for (int i = 0; i &lt; (hexStr.Length / 2); i++)
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; byte firstNibble = Byte.Parse(hexStr.Substring((2 * i), 1), System.Globalization.NumberStyles.HexNumber); // [x,y)
&nbsp; &nbsp; &nbsp; &nbsp; byte secondNibble = Byte.Parse(hexStr.Substring((2 * i) + 1, 1), System.Globalization.NumberStyles.HexNumber);
&nbsp; &nbsp; &nbsp; &nbsp; int finalByte = (secondNibble) | (firstNibble &lt;&lt; 4); // bit-operations only with numbers, not bytes.
&nbsp; &nbsp; &nbsp; &nbsp; bArray[i] = (byte)finalByte;
&nbsp; &nbsp; }
&nbsp; &nbsp; return bArray;
}

/*
&nbsp;* Generates GUID as a string and remove brackets
&nbsp;*/
public static string getNewId()
{
&nbsp; &nbsp; string sR = Guid.NewGuid().ToString().ToUpper();
&nbsp; &nbsp; sR = sR.Replace(&quot;{&quot;, &quot;&quot;);
&nbsp; &nbsp; sR = sR.Replace(&quot;}&quot;, &quot;&quot;);
&nbsp; &nbsp; return sR;
}

/*
&nbsp;* Generates the QR code for authenticator as a base64 encoded svg image
&nbsp;* You must use something like
&nbsp;* &lt;img runat=&quot;server&quot; id=&quot;qrCode&quot; name=&quot;qrCode&quot; src=&quot;javascript:&quot; alt=&quot;Scan this QR code with your mobile application&quot; style=&quot;height:300px;width:300px&quot;/&gt;
&nbsp;*/
private void generateQRCode()
{
&nbsp; &nbsp; //create new key based on hash to be used
&nbsp; &nbsp; string seed = getNewId() + getNewId();
&nbsp; &nbsp; seed = seed.Replace(&quot;-&quot;, &quot;&quot;);
&nbsp; &nbsp; seed = seed.Substring(0, 40);

&nbsp; &nbsp; byte[] byteSeed = HexToByte(seed);


&nbsp;   //Must save this seed to be able to validate the TOTP
&nbsp; &nbsp; var KeyString = Base32.ToBase32String(byteSeed);

&nbsp; &nbsp; string orgDomain = &quot;elogic.synology.me&quot;;
&nbsp; &nbsp; string orgName = &quot;eLogic Builders Inc.&quot;;
&nbsp; &nbsp; string userUPN = &quot;Kashif&quot; + &#39;@&#39; + orgDomain;

&nbsp; &nbsp; const string AuthenticatorUriFormat = &quot;otpauth://totp/{0}:{1}?secret={2}&amp;issuer={0}&amp;algorithm=SHA1&amp;digits=6&amp;period=30&quot;;

&nbsp; &nbsp; string tokenURI = string.Format(
&nbsp; &nbsp; &nbsp; &nbsp; AuthenticatorUriFormat,
&nbsp; &nbsp; &nbsp; &nbsp; HttpUtility.UrlEncode(orgDomain),
&nbsp; &nbsp; &nbsp; &nbsp; HttpUtility.UrlEncode(userUPN),
&nbsp; &nbsp; &nbsp; &nbsp; KeyString);


&nbsp; &nbsp; var qr = QrCode.EncodeText(tokenURI, QrCode.Ecc.High);

&nbsp; &nbsp; string base64EncodedImage = Convert.ToBase64String(Encoding.UTF8.GetBytes(qr.ToSvgString(4)));

&nbsp; &nbsp; string imageSrc = &quot;data:image/svg+xml;base64,&quot; + base64EncodedImage;

&nbsp; &nbsp; //Assign image here in your ASP application
&nbsp; &nbsp; //this.qrCode.Src = imageSrc;
}
</pre>

<p>The&nbsp;<code>KeyString</code>&nbsp;(TOTP seed) must be saved and linked to the user being authenticated. The same seed will be used to authenticate user&#39;s entered TOTP. To generate the QR code, I used <strong>Net.Codecrete.QrCodeGenerator</strong>&nbsp;nuget.org package. This is good to generate QR code on Windows and Linux (using Mono framework). You can use other implementations which suits your application.</p>

<p>Below is the example of a registration link I used to send for registration:</p>

<p style="text-align: center"><img src="images/emaillink.jpg" style="width: 500px; height: 62px" /></p>

<p>When user follows the link, the QR code generation and registration sequence starts. Here is what is presented to the user:</p>

<p style="text-align: center"><img src="images/qrcode.jpg" style="width: 500px; height: 446px" /></p>

<p>User scans the QR code with the Microsoft or Google, or with any other <a href="https://datatracker.ietf.org/doc/html/rfc6238">RFC-6238</a> compliant TOTP authenticator application. The application should register the seed and user&#39;s UPN and should start generating the TOTPs:</p>

<p style="text-align: center"><img src="images/oath2.jpg" style="width: 400px; height: 905px" /></p>

<p>Using the<a href="https://datatracker.ietf.org/doc/html/rfc6238"> RFC-6238</a> compliant class below, you could validate the generated TOTP (it is little modified Microsoft code sample version):</p>

<pre lang="cs">
using System;
using System.Diagnostics;
using System.Net;
using System.Security.Cryptography;
using System.Text;


class SecurityToken
{
&nbsp; &nbsp; private readonly byte[] _data;

&nbsp; &nbsp; public SecurityToken(byte[] data)
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; _data = (byte[])data.Clone();
&nbsp; &nbsp; }

&nbsp; &nbsp; internal byte[] GetDataNoClone()
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; return _data;
&nbsp; &nbsp; }
}

public static class Rfc6238AuthenticationService
{
&nbsp; &nbsp; private static readonly DateTime _unixEpoch = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);
&nbsp; &nbsp; private static readonly TimeSpan _timestep = TimeSpan.FromMinutes(3);
&nbsp; &nbsp; private static readonly Encoding _encoding = new UTF8Encoding(false, true);

&nbsp; &nbsp; public static int ComputeTotp(HashAlgorithm hashAlgorithm, ulong timestepNumber, string modifier)
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; // # of 0&#39;s = length of pin
&nbsp; &nbsp; &nbsp; &nbsp; const int mod = 1000000;

&nbsp; &nbsp; &nbsp; &nbsp; // See https://tools.ietf.org/html/rfc4226
&nbsp; &nbsp; &nbsp; &nbsp; // We can add an optional modifier
&nbsp; &nbsp; &nbsp; &nbsp; var timestepAsBytes = BitConverter.GetBytes(IPAddress.HostToNetworkOrder((long)timestepNumber));
&nbsp; &nbsp; &nbsp; &nbsp; var hash = hashAlgorithm.ComputeHash(ApplyModifier(timestepAsBytes, modifier));

&nbsp; &nbsp; &nbsp; &nbsp; // Generate DT string
&nbsp; &nbsp; &nbsp; &nbsp; var offset = hash[hash.Length - 1] &amp; 0xf;
&nbsp; &nbsp; &nbsp; &nbsp; Debug.Assert(offset + 4 &lt; hash.Length);
&nbsp; &nbsp; &nbsp; &nbsp; var binaryCode = (hash[offset] &amp; 0x7f) &lt;&lt; 24
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;| (hash[offset + 1] &amp; 0xff) &lt;&lt; 16
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;| (hash[offset + 2] &amp; 0xff) &lt;&lt; 8
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;| (hash[offset + 3] &amp; 0xff);

&nbsp; &nbsp; &nbsp; &nbsp; return binaryCode % mod;
&nbsp; &nbsp; }

&nbsp; &nbsp; private static byte[] ApplyModifier(byte[] input, string modifier)
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; if (String.IsNullOrEmpty(modifier))
&nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; return input;
&nbsp; &nbsp; &nbsp; &nbsp; }

&nbsp; &nbsp; &nbsp; &nbsp; var modifierBytes = _encoding.GetBytes(modifier);
&nbsp; &nbsp; &nbsp; &nbsp; var combined = new byte[checked(input.Length + modifierBytes.Length)];
&nbsp; &nbsp; &nbsp; &nbsp; Buffer.BlockCopy(input, 0, combined, 0, input.Length);
&nbsp; &nbsp; &nbsp; &nbsp; Buffer.BlockCopy(modifierBytes, 0, combined, input.Length, modifierBytes.Length);
&nbsp; &nbsp; &nbsp; &nbsp; return combined;
&nbsp; &nbsp; }

&nbsp; &nbsp; // More info: https://tools.ietf.org/html/rfc6238#section-4
&nbsp; &nbsp; private static ulong GetCurrentTimeStepNumber()
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; var delta = DateTime.UtcNow - _unixEpoch;
&nbsp; &nbsp; &nbsp; &nbsp; return (ulong)(delta.Ticks / _timestep.Ticks);
&nbsp; &nbsp; }

&nbsp; &nbsp; private static int GenerateCode(SecurityToken securityToken, string modifier = null)
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; if (securityToken == null)
&nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; throw new ArgumentNullException(&quot;securityToken&quot;);
&nbsp; &nbsp; &nbsp; &nbsp; }

&nbsp; &nbsp; &nbsp; &nbsp; // Allow a variance of no greater than 9 minutes in either direction
&nbsp; &nbsp; &nbsp; &nbsp; var currentTimeStep = GetCurrentTimeStepNumber();
&nbsp; &nbsp; &nbsp; &nbsp; using (var hashAlgorithm = new HMACSHA1(securityToken.GetDataNoClone()))
&nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; return ComputeTotp(hashAlgorithm, currentTimeStep, modifier);
&nbsp; &nbsp; &nbsp; &nbsp; }
&nbsp; &nbsp; }

&nbsp; &nbsp; private static bool ValidateCode(SecurityToken securityToken, int code, string modifier = null)
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; if (securityToken == null)
&nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; throw new ArgumentNullException(&quot;securityToken&quot;);
&nbsp; &nbsp; &nbsp; &nbsp; }

&nbsp; &nbsp; &nbsp; &nbsp; // Allow a variance of no greater than 9 minutes in either direction
&nbsp; &nbsp; &nbsp; &nbsp; var currentTimeStep = GetCurrentTimeStepNumber();
&nbsp; &nbsp; &nbsp; &nbsp; using (var hashAlgorithm = new HMACSHA1(securityToken.GetDataNoClone()))
&nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; for (var i = -2; i &lt;= 2; i++)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; var computedTotp = ComputeTotp(hashAlgorithm, (ulong)((long)currentTimeStep + i), modifier);
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; if (computedTotp == code)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; return true;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; }
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; }
&nbsp; &nbsp; &nbsp; &nbsp; }

&nbsp; &nbsp; &nbsp; &nbsp; // No match
&nbsp; &nbsp; &nbsp; &nbsp; return false;
&nbsp; &nbsp; }
}
</pre>

<p>Here is the function you can use to validate the generated TOTP:</p>

<pre lang="cs">
&nbsp; &nbsp; public bool CheckTimeBasedOTP_Rfc6238(byte[] byteSeed, string incomingOTP)
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; bool bR = false;
&nbsp; &nbsp; &nbsp; &nbsp; int IntIncomingCode = int.Parse(incomingOTP);

&nbsp; &nbsp; &nbsp; &nbsp; var hash = new HMACSHA1(byteSeed);
&nbsp; &nbsp; &nbsp; &nbsp; var unixTimestamp = Convert.ToInt64(Math.Round((DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0)).TotalSeconds));
&nbsp; &nbsp; &nbsp; &nbsp; var timestep = Convert.ToInt64(unixTimestamp / 30);
&nbsp; &nbsp; &nbsp; &nbsp; // Allow codes from 90s in each direction (we could make this configurable?)
&nbsp; &nbsp; &nbsp; &nbsp; for (long i = -2; i &lt;= 2; i++)
&nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; var expectedCode = Rfc6238AuthenticationService.ComputeTotp(hash, (ulong)(timestep + i), modifier: null);
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; if (expectedCode == IntIncomingCode)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; bR = true;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; break;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; }
&nbsp; &nbsp; &nbsp; &nbsp; }

&nbsp; &nbsp; &nbsp; &nbsp; return bR;
&nbsp; &nbsp; }
</pre>

<p>The&nbsp;<code>byteSeed</code> is a byte array you can convert from <strong>Base32 encoded and saved seed</strong>.</p>

<h2>Base32 Encoder / Decoder:</h2>

<pre lang="cs">
using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

public static class Base32
{
&nbsp; &nbsp; private static readonly char[] _digits = &quot;ABCDEFGHIJKLMNOPQRSTUVWXYZ234567&quot;.ToCharArray();
&nbsp; &nbsp; private const int _mask = 31;
&nbsp; &nbsp; private const int _shift = 5;

&nbsp; &nbsp; private static int CharToInt(char c)
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; switch (c)
&nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;A&#39;: return 0;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;B&#39;: return 1;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;C&#39;: return 2;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;D&#39;: return 3;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;E&#39;: return 4;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;F&#39;: return 5;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;G&#39;: return 6;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;H&#39;: return 7;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;I&#39;: return 8;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;J&#39;: return 9;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;K&#39;: return 10;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;L&#39;: return 11;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;M&#39;: return 12;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;N&#39;: return 13;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;O&#39;: return 14;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;P&#39;: return 15;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;Q&#39;: return 16;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;R&#39;: return 17;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;S&#39;: return 18;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;T&#39;: return 19;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;U&#39;: return 20;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;V&#39;: return 21;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;W&#39;: return 22;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;X&#39;: return 23;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;Y&#39;: return 24;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;Z&#39;: return 25;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;2&#39;: return 26;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;3&#39;: return 27;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;4&#39;: return 28;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;5&#39;: return 29;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;6&#39;: return 30;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; case &#39;7&#39;: return 31;
&nbsp; &nbsp; &nbsp; &nbsp; }
&nbsp; &nbsp; &nbsp; &nbsp; return -1;
&nbsp; &nbsp; }

&nbsp; &nbsp; public static byte[] FromBase32String(string encoded)
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; if (encoded == null)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; throw new ArgumentNullException(nameof(encoded));

&nbsp; &nbsp; &nbsp; &nbsp; // Remove whitespace and padding. Note: the padding is used as hint&nbsp;
&nbsp; &nbsp; &nbsp; &nbsp; // to determine how many bits to decode from the last incomplete chunk
&nbsp; &nbsp; &nbsp; &nbsp; // Also, canonicalize to all upper case
&nbsp; &nbsp; &nbsp; &nbsp; encoded = encoded.Trim().TrimEnd(&#39;=&#39;).ToUpper();
&nbsp; &nbsp; &nbsp; &nbsp; if (encoded.Length == 0)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; return new byte[0];

&nbsp; &nbsp; &nbsp; &nbsp; var outLength = encoded.Length * _shift / 8;
&nbsp; &nbsp; &nbsp; &nbsp; var result = new byte[outLength];
&nbsp; &nbsp; &nbsp; &nbsp; var buffer = 0;
&nbsp; &nbsp; &nbsp; &nbsp; var next = 0;
&nbsp; &nbsp; &nbsp; &nbsp; var bitsLeft = 0;
&nbsp; &nbsp; &nbsp; &nbsp; var charValue = 0;
&nbsp; &nbsp; &nbsp; &nbsp; foreach (var c in encoded)
&nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; charValue = CharToInt(c);
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; if (charValue &lt; 0)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; throw new FormatException(&quot;Illegal character: `&quot; + c + &quot;`&quot;);

&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; buffer &lt;&lt;= _shift;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; buffer |= charValue &amp; _mask;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; bitsLeft += _shift;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; if (bitsLeft &gt;= 8)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; result[next++] = (byte)(buffer &gt;&gt; (bitsLeft - 8));
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; bitsLeft -= 8;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; }
&nbsp; &nbsp; &nbsp; &nbsp; }

&nbsp; &nbsp; &nbsp; &nbsp; return result;
&nbsp; &nbsp; }

&nbsp; &nbsp; public static string ToBase32String(byte[] data, bool padOutput = false)
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; return ToBase32String(data, 0, data.Length, padOutput);
&nbsp; &nbsp; }

&nbsp; &nbsp; public static string ToBase32String(byte[] data, int offset, int length, bool padOutput = false)
&nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; if (data == null)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; throw new ArgumentNullException(nameof(data));

&nbsp; &nbsp; &nbsp; &nbsp; if (offset &lt; 0)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; throw new ArgumentOutOfRangeException(nameof(offset));

&nbsp; &nbsp; &nbsp; &nbsp; if (length &lt; 0)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; throw new ArgumentOutOfRangeException(nameof(length));

&nbsp; &nbsp; &nbsp; &nbsp; if ((offset + length) &gt; data.Length)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; throw new ArgumentOutOfRangeException();

&nbsp; &nbsp; &nbsp; &nbsp; if (length == 0)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; return &quot;&quot;;

&nbsp; &nbsp; &nbsp; &nbsp; // SHIFT is the number of bits per output character, so the length of the
&nbsp; &nbsp; &nbsp; &nbsp; // output is the length of the input multiplied by 8/SHIFT, rounded up.
&nbsp; &nbsp; &nbsp; &nbsp; // The computation below will fail, so don&#39;t do it.
&nbsp; &nbsp; &nbsp; &nbsp; if (length &gt;= (1 &lt;&lt; 28))
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; throw new ArgumentOutOfRangeException(nameof(data));

&nbsp; &nbsp; &nbsp; &nbsp; var outputLength = (length * 8 + _shift - 1) / _shift;
&nbsp; &nbsp; &nbsp; &nbsp; var result = new StringBuilder(outputLength);

&nbsp; &nbsp; &nbsp; &nbsp; var last = offset + length;
&nbsp; &nbsp; &nbsp; &nbsp; int buffer = data[offset++];
&nbsp; &nbsp; &nbsp; &nbsp; var bitsLeft = 8;
&nbsp; &nbsp; &nbsp; &nbsp; while (bitsLeft &gt; 0 || offset &lt; last)
&nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; if (bitsLeft &lt; _shift)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; if (offset &lt; last)
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; buffer &lt;&lt;= 8;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; buffer |= (data[offset++] &amp; 0xff);
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; bitsLeft += 8;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; }
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; else
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; int pad = _shift - bitsLeft;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; buffer &lt;&lt;= pad;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; bitsLeft += pad;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; }
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; }
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; int index = _mask &amp; (buffer &gt;&gt; (bitsLeft - _shift));
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; bitsLeft -= _shift;
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; result.Append(_digits[index]);
&nbsp; &nbsp; &nbsp; &nbsp; }
&nbsp; &nbsp; &nbsp; &nbsp; if (padOutput)
&nbsp; &nbsp; &nbsp; &nbsp; {
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; int padding = 8 - (result.Length % 8);
&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; if (padding &gt; 0) result.Append(&#39;=&#39;, padding == 8 ? 0 : padding);
&nbsp; &nbsp; &nbsp; &nbsp; }
&nbsp; &nbsp; &nbsp; &nbsp; return result.ToString();
&nbsp; &nbsp; }
}
</pre>


<p>1st Version: 08 July 2024</p>
    </main>
</asp:Content>
