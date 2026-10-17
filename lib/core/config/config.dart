class AppConfig {


  /// The version of NoteIt's network sync data structure.
  ///
  /// WHY: Prevents crashes when an older app syncs with a newer one. For example,
  /// if a future update adds a required 'category' field to a Note, an older app
  /// receiving that new JSON won't know how to read it and will crash.
  ///
  /// HOW: Devices broadcast this number over mDNS. If versions do not match,
  /// the app blocks the connection and asks the user to update their other device.
  ///
  /// WHEN TO CHANGE: Only increment this if you change the data models sent over the network.
  static const int syncProtocolVersion = 0;


  /// Its like a "radio frequency" or "channel" our app uses
  /// to shout over the local Wi-Fi. When the Client searches the network,
  /// this string ensures it only discovers NoteIt Hosts, completely ignoring
  /// other network devices like wireless printers, smart TVs, or smart fridges.
  ///
  /// Note: The mDNS protocol STRICTLY requires this format:
  /// It must start with an underscore, have a short name, and end with '._tcp' (or '._udp').
  static const String mdnsServiceType = '_noteitsync._tcp';


}