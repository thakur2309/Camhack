<?php
// Create logs folder if not exists
$folder = "logs";
if (!is_dir($folder)) {
    mkdir($folder, 0777, true);
}

// Get POST data
$data = json_decode(file_get_contents("php://input"), true);

if (isset($data['image'])) {
    $image = $data['image'];

    // Clean the base64 string
    $image = str_replace('data:image/png;base64,', '', $image);
    $image = str_replace(' ', '+', $image);
    $decodedImage = base64_decode($image);

    // Generate filename with timestamp
    $filename = $folder . "/photo_" . date("Y-m-d_H-i-s") . ".png";

    // Save the file
    if (file_put_contents($filename, $decodedImage)) {
        echo json_encode(["status" => "success", "message" => "Image saved"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Failed to save image"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "No image data"]);
}
?>
