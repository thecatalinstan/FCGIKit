<?php
    if ( $_SERVER['REQUEST_METHOD'] == "POST" ) {
        header("Content-type: text/plain; charset=utf-8");
        print_r($_POST);
        print_r($_FILES);
        die();
    }
?><h1>Test Simple Post</h1>
<form action="" method="post" enctype="multipart/form-data" onsubmit="this.action=document.getElementById('target').value">
    <input type="hidden" name="MAX_FILE_SIZE" value="10000000" />
    <div>
        <label for="target">Target</label>
        <select id="target">
            <option value="/app">app</option>
            <option value=""><?php echo basename(__FILE__); ?></option>
        </select>
    </div>
    <div>
        <label for="name">Name</label>
        <input type="text" id="name" name="name" />
    </div>
    <div>
        <label for="email">Email</label>
        <input type="email" id="email" name="email" />
    </div>
    <div>
        <label for="file1">File 1</label>
        <input type="file" id="file1" name="file1" />
    </div>
    <div>
        <label for="file2">File 2</label>
        <input type="file" id="file2" name="file2" />
    </div>
    
    <div>
        <input type="submit" />
    </div>
</form>