window.onload = function() {
    var logbox = document.getElementById('log');
    var msgbox = document.getElementById('message');
    var sock = new WebSocket('ws://localhost:24601');

    sock.onmessage = function(e) {
        logbox.value = e.data + '\n' + logbox.value;
    };

    sock.onopen = function(e) {
        sock.send('helo');
        msgbox.addEventListener('keydown', function(e) {
            if(e.keyCode == 13) {
                var msg = msgbox.value;
                msgbox.value = '';
                sock.send('text' + msg);
            }
        });
    };
};
