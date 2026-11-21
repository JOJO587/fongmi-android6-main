package com.fongmi.android.tv.api.loader;

import com.github.catvod.crawler.Spider;
import com.github.catvod.crawler.SpiderNull;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class PyLoader {
    private final ConcurrentHashMap<String, Spider> spiders;
    private volatile String recent;
    public PyLoader() { spiders = new ConcurrentHashMap<>(); }
    public void clear() { spiders.values().forEach(Spider::destroy); spiders.clear(); recent = null; }
    public void setRecent(String recent) { this.recent = recent; }
    public Spider getSpider(String key, String api, String ext) { return new SpiderNull(); }
    public Object[] proxy(Map<String, String> params) throws Exception { return null; }
}
