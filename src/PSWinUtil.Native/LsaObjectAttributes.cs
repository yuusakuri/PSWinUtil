namespace PSWinUtil.NativeMethods
{
    using System;
    using System.Runtime.InteropServices;

    /// <summary>
    /// Represents the LSA_OBJECT_ATTRIBUTES structure that LsaOpenPolicy requires.
    /// </summary>
    [StructLayout(LayoutKind.Sequential)]
    public struct LsaObjectAttributes
    {
        /// <summary>
        /// The size of the structure in bytes.
        /// </summary>
        public uint Length;

        /// <summary>
        /// The root directory handle. The Local Security Authority policy API ignores this member.
        /// </summary>
        public IntPtr RootDirectory;

        /// <summary>
        /// The object name. The Local Security Authority policy API ignores this member.
        /// </summary>
        public IntPtr ObjectName;

        /// <summary>
        /// The object attribute flags. The Local Security Authority policy API ignores this member.
        /// </summary>
        public uint Attributes;

        /// <summary>
        /// The security descriptor. The Local Security Authority policy API ignores this member.
        /// </summary>
        public IntPtr SecurityDescriptor;

        /// <summary>
        /// The quality of service. The Local Security Authority policy API ignores this member.
        /// </summary>
        public IntPtr SecurityQualityOfService;
    }
}
