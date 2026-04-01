package com.testsphere.util;

public class HtmlUtils {
    private HtmlUtils() {}
    public static String escape(Object value) {
        if (value == null) return "";
        String s = value.toString();
        StringBuilder sb = new StringBuilder(s.length() + 16);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '&':  sb.append("&amp;");  break;
                case '<':  sb.append("&lt;");   break;
                case '>':  sb.append("&gt;");   break;
                case '"':  sb.append("&quot;"); break;
                case '\'': sb.append("&#x27;"); break;
                case '/':  sb.append("&#x2F;"); break;
                default:   sb.append(c);
            }
        }
        return sb.toString();
    }
}
