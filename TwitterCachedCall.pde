interface TwitterCachedCall {
  String getCacheFileName();
  Serializable executeCall();
  void setTwitter(Twitter t);
}
