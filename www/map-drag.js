document.addEventListener("DOMContentLoaded", function () {
    function initDrag(panel) {
        let isDragging = false;
        let startX, startY, origLeft, origTop;

        panel.style.cursor = "move";
        panel.style.userSelect = "none";

        panel.addEventListener("mousedown", function (e) {
            if (e.target.tagName === "INPUT" || e.target.tagName === "LABEL") return;

            isDragging = true;
            startX = e.clientX;
            startY = e.clientY;

            const rect = panel.getBoundingClientRect();
            origLeft = rect.left;
            origTop = rect.top;

            panel.style.right = "auto";
            panel.style.left = origLeft + "px";
            panel.style.top = origTop  + "px";
            panel.style.position = "fixed";

            const computed = window.getComputedStyle(panel);
            origLeft = parseFloat(computed.left);
            origTop = parseFloat(computed.top);

            e.preventDefault();
        });

        document.addEventListener("mousemove", function (e) {
            if (!isDragging) return;
            panel.style.left = (origLeft + e.clientX - startX) + "px";
            panel.style.top = (origTop + e.clientY - startY) + "px";
        });

        document.addEventListener("mouseup", function () {
            isDragging = false;
        });
    }

    const observer = new MutationObserver(function () {
        const panel = document.querySelector(".map-filter-panel");
        if (panel) {
            observer.disconnect();
            initDrag(panel);
        }
    });

    observer.observe(document.body, { childList: true, subtree: true });
});
