package com.elsworne.stubline.spike.dnscache;

import java.net.InetAddress;
import java.security.Security;

/** Repeats InetAddress lookups while an authoritative DNS record changes. */
public final class DnsCacheMain {
  private DnsCacheMain() {}

  public static void main(String[] args) throws Exception {
    String ttl = args.length > 0 ? args[0] : "30";
    Security.setProperty("networkaddress.cache.ttl", ttl);
    System.out.println(
        "networkaddress.cache.ttl=" + Security.getProperty("networkaddress.cache.ttl"));
    for (int i = 0; i < 15; i++) {
      String address = InetAddress.getByName("service.stubline.test").getHostAddress();
      System.out.println("lookup " + i + ": " + address);
      Thread.sleep(1000);
    }
  }
}
