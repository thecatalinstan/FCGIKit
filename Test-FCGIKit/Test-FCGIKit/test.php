<!DOCTYPE html>
<html>
    <head>
        <title>Simple Form Test</title>
        <script src="//ajax.googleapis.com/ajax/libs/jquery/2.1.0/jquery.min.js"></script>
        <script>
            function commit() {
            	var url = $('#url').text();
            	var type = $('#type').text();
            	var data = {            
                   	name: $('#name').text(),
                   	email: $('#email').text(),
                   	message: $('#message').text()
                };
                var options = {
                    url: url,
                    type : type,
                    data: data
                };
                $('#output').html("");
                $('#request').text(JSON.stringify(options, undefined, 2));

                $.ajax(options).done( function(postResult) { 
                	// console.log(postResult);
                	$('#output').html(postResult);
                });
            }
        	$(document).ready(function() { $('#send').click(function() { commit(); }); });
        </script>
        <style>
            body, html { font-family: "Helvetica Neue", Helvetica, sans-serif; font-weight: 200; font-size: 10px/1.2em; margin: 0; padding: 0; margin: 0; }
            #content { width: 780px; margin: 0 auto; }
            section { border-bottom: 1px dotted #ccc; padding: 0 0 20px 0; }
            #message, #name, #email, #type, #url { padding: 5px; border-radius: 5px; border: 1px solid #ccc; margin-bottom: 5px }
            #name, #email, #type, #url { width: 400px; }
            #message { min-height: 100px; }
            #send { font-family: "Helvetica Neue", Helvetica, sans-serif; font-weight: 200; font-size: 16px; margin-top: 20px; padding: 10px;  }
            .result { overflow: auto; padding: 5px; border-radius: 5px; min-height: 100px; margin-bottom: 5px; background-color: #eee; }
            p.label { margin-bottom: 5px; }
        </style>
    </head>
    <body>
        <div id="content">
            <h1>A simple contact form</h1>
            <section id="config">
            	<p class="label">Name:</p>
                <div id="url" contenteditable="true">/app</div>
                <p class="label">Method:</p>
                <div id="type" contenteditable="true">POST</div>
            </section>
            <section id="form">
                <p class="label">Name:</p>
                <div id="name" contenteditable="true"></div>
                <p class="label">Email:</p>
                <div id="email" contenteditable="true"></div>
                <p class="label">Message:</p>
                <div id="message" contenteditable="true"></div>
                <input id="send" type="submit" value="Send Commit Message" />
            </section>
            <section id="params">
                <h2>Output</h2>
                <div class="result" id="output"></div>
                <h2>Request</h2>
                <pre class="result" id="request"></pre>
            </section>
        </div>
    </body>
</html>