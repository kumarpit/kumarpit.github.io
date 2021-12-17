let icon = document.getElementById("theme-indicator")
icon.addEventListener("click", toggleTheme)

function toggleTheme() {
    if (icon.classList.contains("dark")) {
        document.documentElement.style.setProperty('--clr-dark', '#1a1d23');
        document.documentElement.style.setProperty('--clr-light', '#f1f1f1');
        document.documentElement.style.setProperty('--fc-dark', 'rgba(0, 0, 0, 0.5)');
        document.documentElement.style.setProperty('--fc-darker', 'rgba(0, 0, 0, 0.8)');
        document.documentElement.style.setProperty('--fc-darkest', 'rgba(0, 0, 0, 0.9)');
    } else {
        document.documentElement.style.setProperty('--clr-light', '#1a1d23');
        document.documentElement.style.setProperty('--clr-dark', '#f1f1f1');
        document.documentElement.style.setProperty('--fc-dark', 'rgba(255, 255, 255, 0.5)');
        document.documentElement.style.setProperty('--fc-darker', 'rgba(255, 255, 255, 0.8)');
        document.documentElement.style.setProperty('--fc-darkest', 'rgba(255, 255, 255, 0.9)');
    }

    icon.classList.toggle("fa-moon");
    icon.classList.toggle("fa-sun");
    icon.classList.toggle("dark")
}