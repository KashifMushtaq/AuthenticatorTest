<%@ Page Title="Test Authenticators" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="AuthenticatorTest._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <main>
        <section class="row" aria-labelledby="aspnetTitle">
            <h1 id="aspnetTitle">Microsoft / Google Authenticator Test Application</h1>
            <p class="lead">A time-based, One-time Password Algorithm (RFC-6238, TOTP - HMAC-based One-time Password Algorithm) based token, is implemented by e.g. Microsoft or Google Authenticator mobile applications. Mobile application allows you to register your account with Microsoft / Google or any other TOTP authenticator application (via a specially generated QR code). After successful registration, the authenticator application will generate a new code every 30 seconds, which could be used to implement MFA based sign-in. To make it a complete MFA, a PIN is added as a prefix to the application's generated code. The sign-in password, or some call it Passcode, will be the PIN + Code.</p>
            <p><a href="https://datatracker.ietf.org/doc/html/rfc6238" class="btn btn-primary btn-md">Learn more about RFC-6238&raquo;</a></p>
        </section>

        <div class="row">
            <section class="col-md-4" aria-labelledby="QrCoreCreation" style="padding-top:20px; padding-bottom:20px;">
                <h2 id="QrCoreCreation">The QR Code for test Registration</h2>
                <pstyle="padding-top:20px; padding-bottom:20px;">
                    Please install the Microsoft Authenticator mobile application on your mobile phone and scan the QR code below to register it.
                </pstyle="padding-top:20px;>
                <pstyle="padding-top:20px; padding-bottom:20px;">
                    <img runat="server" id="qrCode" name="qrCode" src="javascript:" alt="Scan this QR code with your mobile application" style="height:300px;width:300px"/>
                </pstyle="padding-top:20px;>

            </section>
            <section class="col-md-4" aria-labelledby="totpTesting" style="padding-top:20px; padding-bottom:20px;">
                <h2 id="gettingStartedTitle">Test TOTP (Authenticator Generated Code)</h2>
                <p style="padding-top:20px; padding-bottom:20px;">
                    After registration, Microsoft or Google Authenticator mobile application generates a code every 30 seconds. Please enter the generated code below for testing
                </p>
                <p style="padding-top:20px; padding-bottom:20px; text-align:center">
                    <asp:Label ID="Label_TOTP" runat="server" Text="TOTP for Testing: "/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                    <asp:TextBox runat="server" id="textBox_TOTP" name="txtTOTP" value="" help="Enter TOTP" MaxLength="6" />
                </p>
                <p style="padding-top:40px; padding-bottom:40px; text-align:center">
                    <asp:Label ID="LabelResult" runat="server" Text="Test Result will be here after you test." style="font-size:larger; color:blue"/>
                </p>
                <p style="padding-top:20px; padding-bottom:20px; text-align:center">
                    <asp:Button runat="server" id="Button_Test" name="Button_Test" Text="Test TOTP" OnClick="Button_Test_Click" />
                </p>
            </section>
        </div>
    </main>

</asp:Content>
