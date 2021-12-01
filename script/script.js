function toggleTheme() {
    let emoji = document.getElementById("theme-indicator")

    if (emoji.classList.contains("dark")) {
        emoji.innerHTML = "&#127761"
        document.documentElement.style.setProperty('--clr-dark', '#f0f2f4');
        document.documentElement.style.setProperty('--clr-light', '#151515');
        emoji.classList.remove("dark")
    } else {
        emoji.innerHTML = "&#9728"
        document.documentElement.style.setProperty('--clr-light', '#f0f2f4');
        document.documentElement.style.setProperty('--clr-dark', '#151515');
        emoji.classList.add("dark")
    }
}