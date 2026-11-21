package org.gradle.util;

/** Shim replacing Gradle's removed org.gradle.util.VersionNumber for Chaquopy 15 on Gradle 9. */
public class VersionNumber implements Comparable<VersionNumber> {
    private final int major, minor, micro;
    private final String qualifier;

    private VersionNumber(int major, int minor, int micro, String qualifier) {
        this.major = major; this.minor = minor; this.micro = micro;
        this.qualifier = qualifier == null ? "" : qualifier;
    }

    public static VersionNumber parse(String version) {
        if (version == null) version = "";
        String v = version.trim();
        String qual = "";
        int dash = v.indexOf('-');
        if (dash >= 0) { qual = v.substring(dash + 1); v = v.substring(0, dash); }
        String[] parts = v.split("\\.");
        int ma = num(parts, 0), mi = num(parts, 1), mc = num(parts, 2);
        return new VersionNumber(ma, mi, mc, qual);
    }

    private static int num(String[] p, int i) {
        if (i >= p.length) return 0;
        try { return Integer.parseInt(p[i].replaceAll("[^0-9].*$", "")); }
        catch (Exception e) { return 0; }
    }

    public int getMajor() { return major; }
    public int getMinor() { return minor; }
    public int getMicro() { return micro; }

    @Override
    public int compareTo(VersionNumber o) {
        if (major != o.major) return Integer.compare(major, o.major);
        if (minor != o.minor) return Integer.compare(minor, o.minor);
        if (micro != o.micro) return Integer.compare(micro, o.micro);
        return qualifier.compareTo(o.qualifier);
    }

    @Override
    public boolean equals(Object obj) {
        return obj instanceof VersionNumber && compareTo((VersionNumber) obj) == 0;
    }

    @Override
    public int hashCode() { return (major * 31 + minor) * 31 + micro; }

    @Override
    public String toString() {
        return major + "." + minor + "." + micro + (qualifier.isEmpty() ? "" : "-" + qualifier);
    }
}
