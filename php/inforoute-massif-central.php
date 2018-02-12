<?php

// Generated by curl-to-PHP: http://incarnate.github.io/curl-to-php/
$ch = curl_init();

// Example data
$subfolder = "cam18";
$id = "15";

$folder = "/var/www/inforoute-massif-central.fr/web/webcam/$subfolder/";
$type = "dirmc";

curl_setopt($ch, CURLOPT_URL, "http://www.inforoute-massif-central.fr/mod_turbolead/mod/inforoute/webcam.php");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, "type=$type&dossier=$folder&id=$id");
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_ENCODING, 'gzip, deflate');

$headers = array();
$headers[] = "Pragma: no-cache";
$headers[] = "Origin: http://www.inforoute-massif-central.fr";
$headers[] = "Accept-Encoding: gzip, deflate";
$headers[] = "Accept-Language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,es;q=0.6,de;q=0.5,cs;q=0.4,pt;q=0.3,la;q=0.2";
$headers[] = "Content-Type: application/x-www-form-urlencoded; charset=UTF-8";
$headers[] = "Accept: application/json, text/javascript, /; q=0.01";
$headers[] = "Cache-Control: no-cache";
$headers[] = "Referer: http://www.inforoute-massif-central.fr/";
$headers[] = "Connection: keep-alive";
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

$result = curl_exec($ch);
if (curl_errno($ch)) {
    echo 'Error: ' . curl_error($ch);
} else {
    // http://www.inforoute-massif-central.fr/webcam/$subfolder/img_2018-02-12_23-12-51_90.jpg
    $json = json_decode($result);
    $filename = $json->filename;
    $url = "http://www.inforoute-massif-central.fr/webcam/$subfolder/$filename";

    // echo $url;
    header("content-type: image/jpeg");
    echo file_get_contents($url);
}

curl_close ($ch);