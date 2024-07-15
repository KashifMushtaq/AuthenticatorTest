# About:

A time-based, One-time Password Algorithm (RFC-6238, TOTP - HMAC-based One-time Password Algorithm) based token, implemented by e.g. Microsoft or Google Authenticator mobile application.
Mobile application allows you to register your account with Microsoft / Google or any other TOTP authenticator application (via a specially generated QR code). After successful registration, the authenticator application will generate a new code every 30 seconds which could be used to implement MFA based sign-in. To make it a complete MFA, a PIN is added as a prefix to the application generated code. The sign-in password or some call it Passcode will be PIN+Code.

<a href="https://www.codeproject.com/Tips/5384961/How-to-add-a-Multifactor-Authentication-using-Micr">How to add a Multifactor Authentication using Microsoft or Google Authenticator</a>
