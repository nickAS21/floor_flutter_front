

class UsrS100HttpClientHelper {

  /**
   * S100
   * module MAC
   * Request URL
      http://192.168.1.1/sys_status_en.html
      Request Method
      GET
      Status Code
      200 OK
      Remote Address
      192.168.1.1:80
      Referrer Policy
      strict-origin-when-cross-origin
   * Response
   * XHR.post('/api/nv/get', 'sys.sn,sys.base_mac,sys.mid,wifi.mode,wifi.ap_ip,wifi.ap_channel,wifi.ap_ssid,wifi.ap_psw,wifi.sta_ssid,wifi.sta_wan,wifi.sta_ip,wifi.sta_mask,wifi.sta_gateway,wifi.
   *
   */

//   POST /api/nv/get HTTP/1.1
//   Accept: */*
// Accept-Encoding: gzip, deflate
// Accept-Language: en-US,en;q=0.9
// Connection: keep-alive
// Content-Length: 172
// Content-Type: text/plain;charset=UTF-8
// Host: 192.168.1.1
// Origin: http://192.168.1.1
// Referer: http://192.168.1.1/sys_status_en.html
// User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36

  // Payload
  // sys.sn,sys.base_mac,sys.mid,wifi.mode,wifi.ap_ip,wifi.ap_channel,wifi.ap_ssid,wifi.ap_psw,wifi.sta_ssid,wifi.sta_wan,wifi.sta_ip,wifi.sta_mask,wifi.sta_gateway,wifi.sta_dns

  /**
   * Response
   * {
      "sys.sn":	"02200725121900000179",
      "sys.base_mac":	"D4AD20E7CE50",
      "sys.mid":	"USR-S100-WA12",
      "wifi.mode":	3,
      "wifi.ap_ip":	"192.168.1.1",
      "wifi.ap_channel":	6,
      "wifi.ap_ssid":	"USR-S100-CE50",
      "wifi.ap_psw":	"NONE",
      "wifi.sta_ssid":	"lebed",
      "wifi.sta_wan":	"DHCP",
      "wifi.sta_ip":	"192.168.1.1",
      "wifi.sta_mask":	"255.255.255.0",
      "wifi.sta_gateway":	"192.168.1.1",
      "wifi.sta_dns":	"192.168.1.1"
      }
   */


  /**
   * Request URL
      http://192.168.1.1/WiFi_set_en.html
      Request Method
      GET
      Status Code
      200 OK
      Remote Address
      192.168.1.1:80
      Referrer Policy
      strict-origin-when-cross-origin

      Request URL
      http://192.168.1.1/api/nv/get
      Request Method
      POST
      Status Code
      200 OK
      Remote Address
      192.168.1.1:80
      Referrer Policy
      strict-origin-when-cross-origin

   */

//   POST /api/nv/get HTTP/1.1
//   Accept: */*
// Accept-Encoding: gzip, deflate
// Accept-Language: en-US,en;q=0.9
// Connection: keep-alive
// Content-Length: 188
// Content-Type: text/plain;charset=UTF-8
// Host: 192.168.1.1
// Origin: http://192.168.1.1
// Referer: http://192.168.1.1/WiFi_set_en.html
// User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36

  /**
      Request Payload
      wifi.mode,wifi.ap_ssid,wifi.ap_psw,wifi.ap_ip,wifi.ap_mask,wifi.sta_wan,wifi.sta_ssid,wifi.sta_psw,wifi.sta_ip,wifi.sta_mask,wifi.sta_gateway,wifi.sta_dns,wifi.accept_sta,wifi.con_interval

      Response
      {
      "wifi.mode":	3,
      "wifi.ap_ssid":	"USR-S100-CE50",
      "wifi.ap_psw":	"NONE",
      "wifi.ap_ip":	"192.168.1.1",
      "wifi.ap_mask":	"255.255.255.0",
      "wifi.sta_wan":	"DHCP",
      "wifi.sta_ssid":	"lebed",
      "wifi.sta_psw":	"lebedhomewiwfi",
      "wifi.sta_ip":	"192.168.1.1",
      "wifi.sta_mask":	"255.255.255.0",
      "wifi.sta_gateway":	"192.168.1.1",
      "wifi.sta_dns":	"192.168.1.1",
      "wifi.accept_sta":	1,
      "wifi.con_interval":	5
      }
   */

  /**
   * Request URL
      http://192.168.1.1/Peripherals_uart0_en.html
      Request Method
      GET
      Status Code
      200 OK
      Remote Address
      192.168.1.1:80
      Referrer Policy
      strict-origin-when-cross-origin
   */
  //  POST /api/nv/get HTTP/1.1
  // Accept: */*
  // Accept-Encoding: gzip, deflate
  // Accept-Language: en-US,en;q=0.9
  // Connection: keep-alive
  // Content-Length: 783
  // Content-Type: text/plain;charset=UTF-8
  // Host: 192.168.1.1
  // Origin: http://192.168.1.1
  // Referer: http://192.168.1.1/Peripherals_uart0_en.html
  // User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36

  /**
   * {
      "uart0.baud_rate":	2400, =
      "uart0.data_bits":	3,
      "uart0.stop_bits":	1,
      "uart0.parity":	0,
      "uart0.flow_ctrl":	0,
      "uart0.auto_pack_c322":	1,
      "uart0.pack_time":	41,
      "uart0.pack_len":	1024,
      "uart0.sock_mode":	1,      Trans
      "uart0.socka_mode":	2,      TCP-Client
      "uart1.socka_mode":	2,      ?
      "uart1.sock_mode":	0,
      "uart0.socka_raddr":	"192.168.8.102",  +
      "uart0.socka_rport":	18903,            +
      "uart0.socka_lport":	0,
      "uart0.socka_cport":	0,
      "uart0.sockb_mode":	2,      TCP-Clien   +
      "uart0.sockb_raddr":	"89.35.145.1",    +
      "uart0.sockb_rport":	8903,             +
      "uart0.sockb_lport":	0,
      "uart1.socka_rport":	9999,
      "uart1.socka_lport":	9999,
      "uart0.sockb_cport":	0,
      "uart0.httpc_mode":	0,
      "uart0.httpc_addr":	"test.usr.cn",
      "uart0.httpc_port":	80,
      "uart0.httpc_url":	"/1.php?",
      "uart0.httpc_filter":	1,
      "uart0.httpc_head":	"NONE",
      "uart0.httpc_timeout":	10,
      "uart0.ws_disp":	0,
      "uart0.reg_mode":	0,
      "uart0.reg_type":	0,
      "uart0.reg_id":	0,
      "uart0.reg_data":	"5553522D53313030",
      "uart0.cloud_id":	"00004155000000000001",
      "uart0.cloud_psw":	"0000test",
      "uart0.heart_type":	0,
      "uart0.heart_data":	"33373337333733373337333733323435333733353337333333373332333234353336333333363435",
      "uart0.heart_time":	30,
      "uart0.encry_en":	0,
      "uart0.encry_key":	"00000000000000000000000000000000",
      "uart0.rfcen":	0,
      "uart0.Modbusa":	0,
      "uart0.Modbusb":	0,
      "uart0.socka_reconn_tm":	0,
      "uart0.sockb_reconn_tm":	0
      }
   */

// List SSID
//   GET /site_survey.html HTTP/1.1
//   Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
// Accept-Encoding: gzip, deflate
// Accept-Language: en-US,en;q=0.9
// Connection: keep-alive
// Host: 192.168.1.1
// Referer: http://192.168.1.1/WiFi_set_en.html
// Upgrade-Insecure-Requests: 1
// User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36

//   POST /api/system/do_func HTTP/1.1
//   Accept: */*
// Accept-Encoding: gzip, deflate
// Accept-Language: en-US,en;q=0.9
// Connection: keep-alive
// Content-Length: 26
// Content-Type: text/plain;charset=UTF-8
// Host: 192.168.1.1
// Origin: http://192.168.1.1
// Referer: http://192.168.1.1/site_survey.html
// User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36

  // Request Pyload
  // do_get_wifi_ap_tablelist()

  // Response
  // {
  // "result": 	"<tr><tr><td class=\"s15\" colspan=\"5\" id=\"scanSiteSurvey\"></td></tr><tr><td id=\"scanSelect\">&nbsp;</td><td class=\"tab_l tab_t tab_r tab_b\" id=\"scanSSID\">SSID</td><td class=\"tab_t tab_r tab_b\" id=\"scanBSSID\">BSSID</td><td class=\"tab_t tab_r tab_b\" id=\"scanRSSI\">RSSI</td><td class=\"tab_t tab_r tab_b\" id=\"scanChannel\">AuthMode</td></tr></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('USR-WIFI232-B2_26D0', '0', '')\"></td><td class=\"tab_l tab_r tab_b\">USR-WIFI232-B2_26D0</td><td class=\"tab_r tab_b\">F4:70:0C:62:26:D0</td><td class=\"tab_r tab_b\">-52</td><td class=\"tab_r tab_b\">OPEN</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('lebed', '3', '')\"></td><td class=\"tab_l tab_r tab_b\">lebed</td><td class=\"tab_r tab_b\">C4:AD:34:BD:82:92</td><td class=\"tab_r tab_b\">-53</td><td class=\"tab_r tab_b\">WPA2PSK</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('USR-WIFI232-B2_5AE0', '0', '')\"></td><td class=\"tab_l tab_r tab_b\">USR-WIFI232-B2_5AE0</td><td class=\"tab_r tab_b\">F4:70:0C:63:5A:E0</td><td class=\"tab_r tab_b\">-53</td><td class=\"tab_r tab_b\">OPEN</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('USR-WIFI232-B2_34D4', '0', '')\"></td><td class=\"tab_l tab_r tab_b\">USR-WIFI232-B2_34D4</td><td class=\"tab_r tab_b\">9C:A5:25:FE:34:D4</td><td class=\"tab_r tab_b\">-56</td><td class=\"tab_r tab_b\">OPEN</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('USR-WIFI232-B2_44DC', '0', '')\"></td><td class=\"tab_l tab_r tab_b\">USR-WIFI232-B2_44DC</td><td class=\"tab_r tab_b\">F4:70:0C:62:44:DC</td><td class=\"tab_r tab_b\">-57</td><td class=\"tab_r tab_b\">OPEN</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('USR-S100-CE54', '0', '')\"></td><td class=\"tab_l tab_r tab_b\">USR-S100-CE54</td><td class=\"tab_r tab_b\">D4:AD:20:E7:CE:55</td><td class=\"tab_r tab_b\">-57</td><td class=\"tab_r tab_b\">OPEN</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('USR-WIFI232-B2_3500', '0', '')\"></td><td class=\"tab_l tab_r tab_b\">USR-WIFI232-B2_3500</td><td class=\"tab_r tab_b\">9C:A5:25:FE:35:00</td><td class=\"tab_r tab_b\">-59</td><td class=\"tab_r tab_b\">OPEN</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('daddy_Bandera', '3', '')\"></td><td class=\"tab_l tab_r tab_b\">daddy_Bandera</td><td class=\"tab_r tab_b\">84:D8:1B:49:5F:75</td><td class=\"tab_r tab_b\">-60</td><td class=\"tab_r tab_b\">WPA2PSK</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('USR-WIFI232-B2_4D2C', '0', '')\"></td><td class=\"tab_l tab_r tab_b\">USR-WIFI232-B2_4D2C</td><td class=\"tab_r tab_b\">F4:70:0C:62:4D:2C</td><td class=\"tab_r tab_b\">-62</td><td class=\"tab_r tab_b\">OPEN</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('USR-WIFI232-B2_661C', '0', '')\"></td><td class=\"tab_l tab_r tab_b\">USR-WIFI232-B2_661C</td><td class=\"tab_r tab_b\">F4:70:0C:62:66:1C</td><td class=\"tab_r tab_b\">-62</td><td class=\"tab_r tab_b\">OPEN</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('Q0033410020284', '4', '')\"></td><td class=\"tab_l tab_r tab_b\">Q0033410020284</td><td class=\"tab_r tab_b\">DA:BC:38:A7:F1:A8</td><td class=\"tab_r tab_b\">-63</td><td class=\"tab_r tab_b\">WPAWPA2PSK</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('TP_38', '7', '')\"></td><td class=\"tab_l tab_r tab_b\">TP_38</td><td class=\"tab_r tab_b\">9C:A2:F4:CF:2A:4D</td><td class=\"tab_r tab_b\">-73</td><td class=\"tab_r tab_b\">WPA2WPA3PSK</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('officemmmDeco', '3', '')\"></td><td class=\"tab_l tab_r tab_b\">officemmmDeco</td><td class=\"tab_r tab_b\">10:27:F5:D8:14:36</td><td class=\"tab_r tab_b\">-80</td><td class=\"tab_r tab_b\">WPA2PSK</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('BoreyHome', '3', '')\"></td><td class=\"tab_l tab_r tab_b\">BoreyHome</td><td class=\"tab_r tab_b\">04:D9:F5:57:D6:50</td><td class=\"tab_r tab_b\">-83</td><td class=\"tab_r tab_b\">WPA2PSK</td></tr><tr><td><input type=radio name=selectedSSID onClick=\"selectedSSIDChange('lebed', '3', '')\"></td><td class=\"tab_l tab_r tab_b\">lebed</td><td class=\"tab_r tab_b\">00:0C:42:8D:21:E9</td><td class=\"tab_r tab_b\">-83</td><td class=\"tab_r tab_b\">WPA2PSK</td></tr>"
  // }


  // Save Ssid/pwd
//   POST /api/nv/set HTTP/1.1
//   Accept: */*
// Accept-Encoding: gzip, deflate
// Accept-Language: en-US,en;q=0.9
// Connection: keep-alive
// Content-Length: 314
// Content-Type: text/plain;charset=UTF-8
// Host: 192.168.1.1
// Origin: http://192.168.1.1
// Referer: http://192.168.1.1/WiFi_set_en.html
// User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36


// Pyload
//   wifi.mode=3,wifi.ap_ssid=USR-S100-CE50,wifi.ap_ip=192.168.1.1,wifi.ap_mask=255.255.255.0,wifi.accept_sta=1,wifi.ap_psw=NONE,wifi.sta_ssid=lebed,wifi.sta_psw=lebedhomewifi,wifi.sta_wan=DHCP,wifi.sta_ip=192.168.1.1,wifi.sta_mask=255.255.255.0,wifi.sta_gateway=192.168.1.1,wifi.sta_dns=192.168.1.1,wifi.con_interval=5

// Response
// {"result": "ok"}

// Restart
// 192.168.1.1says
// Cancel/ok
// Headers
//   POST /api/system/do_func HTTP/1.1
//   Accept: */*
// Accept-Encoding: gzip, deflate
// Accept-Language: en-US,en;q=0.9
// Connection: keep-alive
// Content-Length: 16
// Content-Type: text/plain;charset=UTF-8
// Host: 192.168.1.1
// Origin: http://192.168.1.1
// Referer: http://192.168.1.1/do_cmd_en.html
// User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36
// Pyload
// do_esp_restart()
// Response
// {
// 	"result":	"ok"
// }

// After restart - reconnect
//   POST /api/nv/get HTTP/1.1
//   Accept: */*
// Accept-Encoding: gzip, deflate
// Accept-Language: en-US,en;q=0.9
// Connection: keep-alive
// Content-Length: 188
// Content-Type: text/plain;charset=UTF-8
// Host: 192.168.1.1
// Origin: http://192.168.1.1
// Referer: http://192.168.1.1/WiFi_set_en.html
// User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36

// Payload
//wifi.mode,wifi.ap_ssid,wifi.ap_psw,wifi.ap_ip,wifi.ap_mask,wifi.sta_wan,wifi.sta_ssid,wifi.sta_psw,wifi.sta_ip,wifi.sta_mask,wifi.sta_gateway,wifi.sta_dns,wifi.accept_sta,wifi.con_interval
// Response
//   {
//   "wifi.mode":	3,
//   "wifi.ap_ssid":	"USR-S100-CE50",
//   "wifi.ap_psw":	"NONE",
//   "wifi.ap_ip":	"192.168.1.1",
//   "wifi.ap_mask":	"255.255.255.0",
//   "wifi.sta_wan":	"DHCP",
//   "wifi.sta_ssid":	"lebed",
//   "wifi.sta_psw":	"lebedhomewifi",
//   "wifi.sta_ip":	"192.168.1.1",
//   "wifi.sta_mask":	"255.255.255.0",
//   "wifi.sta_gateway":	"192.168.1.1",
//   "wifi.sta_dns":	"192.168.1.1",
//   "wifi.accept_sta":	1,
//   "wifi.con_interval":	5
//   }

  static const String s100SearchKeyword = "www.usr.cn";
  static const int s100UdpPort = 48899;
}