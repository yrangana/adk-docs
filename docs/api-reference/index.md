<script>
  function resizeIframe(obj) {
    obj.style.height = obj.contentWindow.document.documentElement.scrollHeight + 'px';
  }
</script>

<iframe src="reference.html" scrolling="no" onload="resizeIframe(this)"></iframe>

<style>
iframe {
    min-height: 1000vh;
    min-width: 60vw;
    border: 0;
    overflow: hidden;
}
</style>
