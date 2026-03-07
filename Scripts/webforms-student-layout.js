(function () {
    function applyDarkMode(enabled) {
        var html = document.documentElement;
        var body = document.body;
        var themeClasses = [
            "theme-deep-red",
            "theme-deep-blue",
            "theme-light-blue",
            "theme-light-green",
            "theme-ocean-blue",
            "theme-light-purple"
        ];

        themeClasses.forEach(function (cls) {
            html.classList.remove(cls);
            if (body) {
                body.classList.remove(cls);
            }
        });

        html.classList.toggle("dark-mode", enabled);
        if (body) {
            body.classList.toggle("dark-mode", enabled);
        }

        document.querySelectorAll(".dark-toggle-btn").forEach(function (btn) {
            btn.textContent = enabled ? "浅色模式" : "暗色模式";
        });
    }

    function bindDarkModeToggle() {
        var initial = localStorage.getItem("theme") === "dark";
        applyDarkMode(initial);

        document.querySelectorAll(".dark-toggle-btn").forEach(function (btn) {
            btn.addEventListener("click", function () {
                var isDark = !(localStorage.getItem("theme") === "dark");
                localStorage.setItem("theme", isDark ? "dark" : "light");
                applyDarkMode(isDark);
            });
        });
    }

    function bindSidebar() {
        var body = document.body;
        var sidebar = document.querySelector('.sidebar');
        var overlay = document.querySelector('.sidebar-overlay');
        var triggers = document.querySelectorAll('.hamburger-menu');

        if (!sidebar || !overlay || !triggers.length) {
            return;
        }

        function openMenu() {
            sidebar.classList.add('visible');
            overlay.classList.add('visible');
        }

        function closeMenu() {
            sidebar.classList.remove('visible');
            overlay.classList.remove('visible');
        }

        function toggleMenu() {
            if (sidebar.classList.contains('visible')) {
                closeMenu();
            } else {
                openMenu();
            }
        }

        triggers.forEach(function (btn) {
            btn.addEventListener('click', function (event) {
                event.preventDefault();
                toggleMenu();
            });
        });

        overlay.addEventListener('click', closeMenu);

        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape') {
                closeMenu();
            }
        });

        sidebar.querySelectorAll('a').forEach(function (link) {
            link.addEventListener('click', function () {
                if (window.innerWidth <= 768) {
                    closeMenu();
                }
            });
        });

        window.addEventListener('resize', function () {
            if (window.innerWidth > 768) {
                closeMenu();
            }
        });

        window.setTimeout(function () {
            body.classList.add('transitions-enabled');
        }, 120);
    }

    function init() {
        bindDarkModeToggle();
        bindSidebar();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
