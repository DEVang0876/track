import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:trackizer/common/supabase_config.dart';

class NetDiagnosticsResult {
  final String host;
  final bool dnsOk;
  final String dnsMessage;
  final bool httpsOk;
  final String httpsMessage;
  NetDiagnosticsResult({
    required this.host,
    required this.dnsOk,
    required this.dnsMessage,
    required this.httpsOk,
    required this.httpsMessage,
  });

  @override
  String toString() {
    final dns = dnsOk ? 'DNS: ok' : 'DNS: $dnsMessage';
    final https = httpsOk ? 'HTTPS: ok' : 'HTTPS: $httpsMessage';
    return '$host → $dns | $https';
  }
}

Future<NetDiagnosticsResult> diagnoseSupabaseConnectivity() async {
  final uri = Uri.parse(SupabaseConfig.effectiveUrl);
  final host = uri.host;
  bool dnsOk = false;
  String dnsMsg = 'unknown';
  try {
    final list = await InternetAddress.lookup(host);
    dnsOk = list.isNotEmpty;
    dnsMsg = dnsOk ? list.map((e) => e.address).join(',') : 'no records';
  } catch (e) {
    dnsOk = false;
    dnsMsg = e.toString();
  }

  bool httpsOk = false;
  String httpsMsg = 'unknown';
  try {
    final health = Uri.parse('${SupabaseConfig.effectiveUrl}/auth/v1/health');
    final res = await http.get(health).timeout(const Duration(seconds: 8));
    httpsOk = res.statusCode >= 200 && res.statusCode < 500;
    httpsMsg = 'code ${res.statusCode}';
  } catch (e) {
    httpsOk = false;
    httpsMsg = e.toString();
  }

  return NetDiagnosticsResult(
    host: host,
    dnsOk: dnsOk,
    dnsMessage: dnsMsg,
    httpsOk: httpsOk,
    httpsMessage: httpsMsg,
  );
}
