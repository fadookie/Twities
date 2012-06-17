interface TwitterCachedCall {
  String getCacheFileName();
  Serializable executeCall();
  Serializable executeCall(long cursor);
  void setTwitter(Twitter t);
}
