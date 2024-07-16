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
using System.Diagnostics;
using System.Net;
using System.Security.Cryptography;
using System.Text;


class SecurityToken
{
    private readonly byte[] _data;

    public SecurityToken(byte[] data)
    {
        _data = (byte[])data.Clone();
    }

    internal byte[] GetDataNoClone()
    {
        return _data;
    }
}

public static class Rfc6238AuthenticationService
{
    private static readonly DateTime _unixEpoch = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);
    private static readonly TimeSpan _timestep = TimeSpan.FromMinutes(3);
    private static readonly Encoding _encoding = new UTF8Encoding(false, true);

    public static int ComputeTotp(HashAlgorithm hashAlgorithm, ulong timestepNumber, string modifier)
    {
        // # of 0's = length of pin
        const int mod = 1000000;

        // See https://tools.ietf.org/html/rfc4226
        // We can add an optional modifier
        var timestepAsBytes = BitConverter.GetBytes(IPAddress.HostToNetworkOrder((long)timestepNumber));
        var hash = hashAlgorithm.ComputeHash(ApplyModifier(timestepAsBytes, modifier));

        // Generate DT string
        var offset = hash[hash.Length - 1] & 0xf;
        Debug.Assert(offset + 4 < hash.Length);
        var binaryCode = (hash[offset] & 0x7f) << 24
                | (hash[offset + 1] & 0xff) << 16
                | (hash[offset + 2] & 0xff) << 8
                | (hash[offset + 3] & 0xff);

        return binaryCode % mod;
    }

    private static byte[] ApplyModifier(byte[] input, string modifier)
    {
        if (String.IsNullOrEmpty(modifier))
        {
            return input;
        }

        var modifierBytes = _encoding.GetBytes(modifier);
        var combined = new byte[checked(input.Length + modifierBytes.Length)];
        Buffer.BlockCopy(input, 0, combined, 0, input.Length);
        Buffer.BlockCopy(modifierBytes, 0, combined, input.Length, modifierBytes.Length);
        return combined;
    }

    // More info: https://tools.ietf.org/html/rfc6238#section-4
    private static ulong GetCurrentTimeStepNumber()
    {
        var delta = DateTime.UtcNow - _unixEpoch;
        return (ulong)(delta.Ticks / _timestep.Ticks);
    }

    private static int GenerateCode(SecurityToken securityToken, string modifier = null)
    {
        if (securityToken == null)
        {
            throw new ArgumentNullException("securityToken");
        }

        // Allow a variance of no greater than 9 minutes in either direction
        var currentTimeStep = GetCurrentTimeStepNumber();
        using (var hashAlgorithm = new HMACSHA1(securityToken.GetDataNoClone()))
        {
            return ComputeTotp(hashAlgorithm, currentTimeStep, modifier);
        }
    }

    private static bool ValidateCode(SecurityToken securityToken, int code, string modifier = null)
    {
        if (securityToken == null)
        {
            throw new ArgumentNullException("securityToken");
        }

        // Allow a variance of no greater than 9 minutes in either direction
        var currentTimeStep = GetCurrentTimeStepNumber();
        using (var hashAlgorithm = new HMACSHA1(securityToken.GetDataNoClone()))
        {
            for (var i = -2; i <= 2; i++)
            {
                var computedTotp = ComputeTotp(hashAlgorithm, (ulong)((long)currentTimeStep + i), modifier);
                if (computedTotp == code)
                {
                    return true;
                }
            }
        }

        // No match
        return false;
    }
}