<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Sync-Key");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Kunci otentikasi rahasia untuk sinkronisasi
define('SECRET_SYNC_KEY', 'segari_lukman_sync_2026');

$authKey = $_GET['key'] ?? $_SERVER['HTTP_X_SYNC_KEY'] ?? '';

if ($authKey !== SECRET_SYNC_KEY) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "message" => "Unauthorized: Kunci sinkronisasi tidak valid."
    ]);
    exit;
}

$dataDir = __DIR__ . '/data';
if (!file_exists($dataDir)) {
    mkdir($dataDir, 0755, true);
    // Buat .htaccess proteksi agar berkas json tidak bisa diakses publik langsung
    file_put_contents($dataDir . '/.htaccess', "Deny from all\n");
}

$dataFile = $dataDir . '/segari_user_data.json';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $rawInput = file_get_contents('php://input');
    $decoded = json_decode($rawInput, true);

    if (!$decoded) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "message" => "Format JSON tidak valid."
        ]);
        exit;
    }

    // Tambahkan metadata sinkronisasi
    $payload = [
        "sync_metadata" => [
            "synced_at" => date('Y-m-d H:i:s'),
            "server_time" => time(),
            "client_ip" => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        ],
        "data" => $decoded
    ];

    $saved = file_put_contents($dataFile, json_encode($payload, JSON_PRETTY_PRINT));

    if ($saved !== false) {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "message" => "Data Segari berhasil disinkronkan ke server AI!",
            "synced_at" => date('Y-m-d H:i:s'),
            "records_count" => count($decoded['records'] ?? []),
            "sku_count" => count($decoded['sku_entries'] ?? []),
            "penalties_count" => count($decoded['penalties'] ?? [])
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "message" => "Gagal menulis file ke server storage."
        ]);
    }
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (!file_exists($dataFile)) {
        http_response_code(404);
        echo json_encode([
            "status" => "empty",
            "message" => "Belum ada data sinkronisasi yang tersimpan di server."
        ]);
        exit;
    }

    $content = file_get_contents($dataFile);
    http_response_code(200);
    echo $content;
    exit;
}

http_response_code(405);
echo json_encode([
    "status" => "error",
    "message" => "Metode HTTP tidak didukung."
]);
