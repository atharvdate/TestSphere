package com.testsphere.util;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import java.sql.*;
import java.util.concurrent.*;
import java.util.logging.Logger;

/**
 * Runs every 60 seconds. Finds any APTITUDE round whose end_time has passed,
 * has a cutoff set by the recruiter, and has not yet been released.
 * Automatically scores, applies cutoff, eliminates failed applicants, and notifies students.
 */
@WebListener
public class ResultAutoReleaseScheduler implements ServletContextListener {

    private static final Logger log = Logger.getLogger(ResultAutoReleaseScheduler.class.getName());
    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "auto-release-scheduler");
            t.setDaemon(true);
            return t;
        });
        // Run immediately then every 60 seconds
        scheduler.scheduleAtFixedRate(this::processExpiredRounds, 10, 60, TimeUnit.SECONDS);
        log.info("ResultAutoReleaseScheduler started.");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) scheduler.shutdownNow();
    }

    private void processExpiredRounds() {
        try (Connection conn = DBConnection.getConnection()) {
            // Find expired APTITUDE rounds that have a cutoff set but not yet released
            String findSql =
                "SELECT id, cutoff_type, cutoff_value, drive_id " +
                "FROM drive_rounds " +
                "WHERE round_type = 'APTITUDE' " +
                "  AND status != 'COMPLETED' " +
                "  AND result_released = 0 " +
                "  AND end_time IS NOT NULL " +
                "  AND NOW() > end_time " +
                "  AND cutoff_type IS NOT NULL " +
                "  AND cutoff_value IS NOT NULL";

            try (PreparedStatement ps = conn.prepareStatement(findSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int roundId     = rs.getInt("id");
                    String cutoffType  = rs.getString("cutoff_type");
                    String cutoffValue = rs.getString("cutoff_value");
                    int driveId     = rs.getInt("drive_id");
                    try {
                        releaseRound(conn, roundId, driveId, cutoffType, cutoffValue);
                        log.info("Auto-released round " + roundId + " (cutoff=" + cutoffType + ":" + cutoffValue + ")");
                    } catch (Exception e) {
                        log.severe("Failed to auto-release round " + roundId + ": " + e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            log.severe("Auto-release scheduler error: " + e.getMessage());
        }
    }

    private void releaseRound(Connection conn, int roundId, int driveId,
                              String cutoffType, String cutoffValue) throws SQLException {

        // 1. Apply cutoff — mark pass/fail on submitted results
        if ("TOP_N".equals(cutoffType)) {
            int n = Integer.parseInt(cutoffValue);
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE round_results rr " +
                    "JOIN (SELECT id, RANK() OVER (ORDER BY (score*100.0/NULLIF(total_questions,0)) DESC) AS rnk " +
                    "      FROM round_results WHERE round_id=? AND submitted_at IS NOT NULL) ranked " +
                    "  ON rr.id = ranked.id " +
                    "SET rr.pass_fail = CASE WHEN ranked.rnk <= ? THEN 'PASS' ELSE 'FAIL' END " +
                    "WHERE rr.round_id = ?")) {
                ps.setInt(1, roundId); ps.setInt(2, n); ps.setInt(3, roundId);
                ps.executeUpdate();
            }
        } else { // MIN_PERCENT
            double minPct = Double.parseDouble(cutoffValue);
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE round_results SET " +
                    "pass_fail = CASE WHEN total_questions>0 AND (score*100.0/total_questions)>=? THEN 'PASS' ELSE 'FAIL' END " +
                    "WHERE round_id=? AND submitted_at IS NOT NULL")) {
                ps.setDouble(1, minPct); ps.setInt(2, roundId);
                ps.executeUpdate();
            }
        }

        // 2. Students who didn't submit at all get FAIL
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO round_results (application_id, round_id, score, total_questions, pass_fail, submitted_at) " +
                "SELECT da.id, ?, 0, " +
                "  (SELECT COUNT(*) FROM questions q WHERE q.round_id=?), " +
                "  'FAIL', NOW() " +
                "FROM drive_applications da " +
                "WHERE da.drive_id=? AND da.status='ACTIVE' " +
                "  AND NOT EXISTS (SELECT 1 FROM round_results rr WHERE rr.application_id=da.id AND rr.round_id=?) " +
                "ON DUPLICATE KEY UPDATE pass_fail='FAIL'")) {
            ps.setInt(1, roundId); ps.setInt(2, roundId);
            ps.setInt(3, driveId); ps.setInt(4, roundId);
            ps.executeUpdate();
        }

        // 3. Mark round as released and COMPLETED
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE drive_rounds SET result_released=1, status='COMPLETED' WHERE id=?")) {
            ps.setInt(1, roundId);
            ps.executeUpdate();
        }

        // 4. Eliminate applicants who failed
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE drive_applications da " +
                "JOIN round_results rr ON rr.application_id=da.id " +
                "SET da.status='ELIMINATED', da.current_round=? " +
                "WHERE rr.round_id=? AND rr.pass_fail='FAIL' AND da.status='ACTIVE'")) {
            ps.setInt(1, roundId); ps.setInt(2, roundId);
            ps.executeUpdate();
        }

        // 5. Fetch drive title for notifications
        String driveTitle = "";
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT title FROM drives WHERE id=?")) {
            ps.setInt(1, driveId);
            ResultSet tr = ps.executeQuery();
            if (tr.next()) driveTitle = tr.getString(1);
        }

        // 6. Notify all applicants
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO notifications (user_id, title, message) " +
                "SELECT u.id, ?, CASE rr.pass_fail WHEN 'PASS' THEN ? ELSE ? END " +
                "FROM round_results rr " +
                "JOIN drive_applications da ON rr.application_id=da.id " +
                "JOIN users u ON da.student_id=u.id " +
                "WHERE rr.round_id=?")) {
            ps.setString(1, "Result Released: " + driveTitle);
            ps.setString(2, "Congratulations! You qualified the aptitude round for " + driveTitle + " and are moving forward.");
            ps.setString(3, "Results are out for " + driveTitle + ". Unfortunately you did not qualify this round.");
            ps.setInt(4, roundId);
            ps.executeUpdate();
        }
    }
}
