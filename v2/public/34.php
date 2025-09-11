<?php

echo "<h1>Hello World</h1>";

echo "File: " . __FILE__ . "<br>";
echo "Line: " . __LINE__ . "<br>";
echo "Directory: " . __DIR__ . "<br>";
echo "Current Time: " . date('Y-m-d H:i:s') . "<br>";
echo "Path Info: " . pathinfo(__FILE__, PATHINFO_BASENAME) . "<br>";
echo "PHP SAPI: " . php_sapi_name() . "<br>";
echo "PHP version: " . phpversion() . "<br>";
echo "Loaded extensions: " . implode(", ", get_loaded_extensions()) . "<br>";
echo "Server Software: " . ($_SERVER['SERVER_SOFTWARE'] ?? 'N/A') . "<br>";
echo "Document Root: " . ($_SERVER['DOCUMENT_ROOT'] ?? 'N/A') . "<br>";
echo "Request URI: " . ($_SERVER['REQUEST_URI'] ?? 'N/A') . "<br>";

?>
