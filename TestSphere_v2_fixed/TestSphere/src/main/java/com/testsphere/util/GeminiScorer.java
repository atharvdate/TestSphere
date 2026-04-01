package com.testsphere.util;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;

/**
 * Scores a student's resume against the job description using
 * Google Gemini 1.5 Flash API (free tier — no credit card needed).
 *
 * Setup:
 *   1. Go to https://aistudio.google.com/app/apikey
 *   2. Create a free API key (no billing required)
 *   3. Replace GEMINI_API_KEY below with your key
 */
public class GeminiScorer {

    // ── CONFIGURE THIS ──────────────────────────────────────────
    private static final String OPENROUTER_API_KEY = "YOUR_API_KEY_HERE";
    // ────────────────────────────────────────────────────────────

    private static final String API_URL =
            "https://openrouter.ai/api/v1/chat/completions";

    private GeminiScorer() {}

    /**
     * Called asynchronously after a student uploads their resume.
     * Extracts PDF text, calls Gemini, stores score + reason in DB.
     */
    public static void scoreAsync(int driveId, int studentId, String resumeFileName) {
        if (OPENROUTER_API_KEY == null || OPENROUTER_API_KEY.isEmpty()) return; // Not configured

        try (Connection conn = DBConnection.getConnection()) {

            // 1. Get job description from drive
            String jobRole = "", description = "";
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT job_role, description FROM drives WHERE id=?")) {
                ps.setInt(1, driveId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    jobRole     = rs.getString("job_role");
                    description = rs.getString("description") != null ? rs.getString("description") : "";
                }
            }

            // 2. Extract text from PDF
            File resumeFile = new File(ResumeUploadConfig.RESUME_UPLOAD_DIR, resumeFileName);
            if (!resumeFile.exists()) return;
            String resumeText = extractPdfText(resumeFile);
            if (resumeText == null || resumeText.trim().length() < 50) return; // unreadable

            // 3. Build prompt
            String prompt = "You are an ATS system evaluating a resume for a campus placement.\n\n" +
                "Job Role: " + jobRole + "\n" +
                "Job Description: " + description + "\n\n" +
                "Resume Text:\n" + resumeText.substring(0, Math.min(resumeText.length(), 3000)) + "\n\n" +
                "Score this resume from 0 to 100 based on fit for the role. " +
                "Reply ONLY with valid JSON in this exact format, nothing else:\n" +
                "{\"score\": <number>, \"reason\": \"<one sentence max 120 chars>\"}";

            // 4. Call Gemini API
            String jsonBody = "{"
                    + "\"model\":\"openrouter/free\","
                    + "\"messages\":["
                    + "{\"role\":\"user\",\"content\":" + jsonString(prompt) + "}"
                    + "]"
                    + "}";

            String response = httpPostOpenRouter(jsonBody);
            if (response == null) return;

            // 5. (Old) Parse response — extract the text content
//            int scoreStart = response.indexOf("\"score\"");
//            int reasonStart = response.indexOf("\"reason\"");
//            if (scoreStart == -1 || reasonStart == -1) return;
//
//            // Simple JSON parsing without external library
//            String inner = response.substring(
//                response.indexOf("{", scoreStart > 0 ? scoreStart - 5 : 0),
//                response.lastIndexOf("}") + 1
//            );
//            // Clean up escaped quotes from Gemini's response wrapper
//            inner = inner.replace("\\\"", "\"").replace("\\n", "").trim();
//
//            int score = -1;
//            String reason = "";
//            try {
//                // Extract score
//                int s1 = inner.indexOf("\"score\"") + 8;
//                String afterScore = inner.substring(s1).trim().replaceFirst("^:\\s*", "");
//                score = Integer.parseInt(afterScore.split("[,}\\s]")[0].trim());
//
//                // Extract reason
//                int r1 = inner.indexOf("\"reason\"") + 9;
//                String afterReason = inner.substring(r1).trim().replaceFirst("^:\\s*\"", "");
//                reason = afterReason.substring(0, afterReason.indexOf("\"")).trim();
//            } catch (Exception e) {
//                return; // Parsing failed — skip storing
//            }
//
//            if (score < 0 || score > 100) return;


            // 5. Parse response — extract the text content
            // Extract JSON safely
            String content = response;

// Step 1: Remove markdown wrapper if exists
            if (content.contains("```")) {
                content = content.substring(content.indexOf("{"), content.lastIndexOf("}") + 1);
            }

// Step 2: Remove escaped quotes
            content = content.replace("\\\"", "\"");

// Step 3: Extract score
            int score = -1;
            String reason = "";

            try {
                int sIndex = content.indexOf("\"score\"");
                int rIndex = content.indexOf("\"reason\"");

                if (sIndex == -1 || rIndex == -1) return;

                String scorePart = content.substring(sIndex).split(":")[1].trim();
                score = Integer.parseInt(scorePart.split("[,}]")[0].trim());

                String reasonPart = content.substring(rIndex).split(":")[1].trim();
                reason = reasonPart.replaceAll("^\"|\"$", "").trim();

            } catch (Exception e) {
                e.printStackTrace();
                return;
            }

//            // 6. Store in DB (old)
//            try (PreparedStatement ps = conn.prepareStatement(
//                    "UPDATE drive_applications SET ai_score=?, ai_reason=? " +
//                    "WHERE drive_id=? AND student_id=?")) {
//                ps.setInt(1, score);
//                ps.setString(2, reason);
//                ps.setInt(3, driveId);
//                ps.setInt(4, studentId);
//                ps.executeUpdate();
//            }

            // 6. Store in DB
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE drive_applications SET ai_score=?, ai_reason=? " +
                            "WHERE drive_id=? AND student_id=?")) {

                ps.setInt(1, score);
                ps.setString(2, reason);
                ps.setInt(3, driveId);
                ps.setInt(4, studentId);

                System.out.println("Saving to DB: score=" + score +
                        ", reason=" + reason +
                        ", driveId=" + driveId +
                        ", studentId=" + studentId);

                int rows = ps.executeUpdate();

                System.out.println("Rows updated: " + rows);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static String extractPdfText(File file) {
        try (PDDocument doc = PDDocument.load(file)) {
            PDFTextStripper stripper = new PDFTextStripper();
            return stripper.getText(doc);
        } catch (Exception e) {
            return null;
        }
    }

    private static String httpPost(String urlStr, String body) {
        try {
            URL url = new URL(urlStr);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(30000);
            conn.setDoOutput(true);
            try (OutputStream os = conn.getOutputStream()) {
                os.write(body.getBytes(StandardCharsets.UTF_8));
            }
            if (conn.getResponseCode() != 200) return null;
            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
                StringBuilder sb = new StringBuilder();
                String line;
                while ((line = br.readLine()) != null) sb.append(line);
                return sb.toString();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    private static String httpPostOpenRouter(String body) {
        try {
            URL url = new URL(API_URL);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();

            conn.setRequestMethod("POST");
            conn.setRequestProperty("Authorization", "Bearer " + OPENROUTER_API_KEY);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(30000);
            conn.setDoOutput(true);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(body.getBytes(StandardCharsets.UTF_8));
            }

            System.out.println("Calling OpenRouter API...");
            if (conn.getResponseCode() != 200) {
                System.out.println("API ERROR CODE: " + conn.getResponseCode());
                return null;
            }

            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
                StringBuilder sb = new StringBuilder();
                String line;
                while ((line = br.readLine()) != null) sb.append(line);

                String res = sb.toString();
                System.out.println("API RESPONSE: " + res);
                return res;
            }

        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /** Escape a Java string for safe embedding in JSON */
    private static String jsonString(String s) {
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
                       .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t") + "\"";
    }
}
