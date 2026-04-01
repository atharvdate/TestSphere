//package com.testsphere.util;
//
///**
// * Central config for resume file storage.
// * Change RESUME_UPLOAD_DIR to wherever Tomcat has write access on your server.
// */
//public class ResumeUploadConfig {
//    /** Absolute path where resume PDFs are stored. Must be writable by Tomcat. */
//    public static final String RESUME_UPLOAD_DIR = "System.getenv("RESUME_DIR")";
//
//    /** Max resume file size: 5 MB */
//    public static final long MAX_FILE_SIZE = 5 * 1024 * 1024;
//
//    private ResumeUploadConfig() {}
//}


package com.testsphere.util;

public class ResumeUploadConfig {

    // Windows absolute path
    public static final String RESUME_UPLOAD_DIR = "System.getenv(\"RESUME_DIR\")";

    // Max resume file size: 5 MB
    public static final long MAX_FILE_SIZE = 5 * 1024 * 1024;

    private ResumeUploadConfig() {}
}