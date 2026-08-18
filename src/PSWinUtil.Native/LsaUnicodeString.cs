namespace PSWinUtil.NativeMethods
{
    using System;
    using System.Runtime.InteropServices;

    /// <summary>
    /// Represents the LSA_UNICODE_STRING structure that the Local Security Authority policy API expects.
    /// </summary>
    [StructLayout(LayoutKind.Sequential)]
    public struct LsaUnicodeString
    {
        /// <summary>
        /// The length of the string in bytes, excluding the terminating null character.
        /// </summary>
        public ushort Length;

        /// <summary>
        /// The size of the buffer in bytes, including the terminating null character.
        /// </summary>
        public ushort MaximumLength;

        /// <summary>
        /// The unmanaged buffer that holds the Unicode string.
        /// </summary>
        public IntPtr Buffer;
    }
}
