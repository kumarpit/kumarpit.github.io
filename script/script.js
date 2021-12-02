let projectButtons = document.getElementsByClassName("see-project");

for (let i = 0; i < projectButtons.length; i++) {
    projectButtons[i].addEventListener("click", function(){toggleDescription(projectButtons[i])})
}

function toggleDescription(button) {
    if (button.classList.contains("expanded")) {
        button.parentNode.parentNode.parentNode.children[1].style.display = "none"
        button.innerHTML = '<i class="fas fa-chevron-down"></i>'
    } else {
        button.parentNode.parentNode.parentNode.children[1].style.display = "block"
        button.innerHTML = '<i class="fas fa-chevron-up"></i>'
    }

    button.classList.toggle("expanded")
}


function toggleTheme() {
    let emoji = document.getElementById("theme-indicator")

    if (emoji.classList.contains("dark")) {
        emoji.innerHTML = "&#127761"
        document.documentElement.style.setProperty('--clr-dark', '#f0f2f4');
        document.documentElement.style.setProperty('--clr-light', '#151515');
    } else {
        emoji.innerHTML = "&#9728"
        document.documentElement.style.setProperty('--clr-light', '#f0f2f4');
        document.documentElement.style.setProperty('--clr-dark', '#151515');
    }

    emoji.classList.toggle("dark")
}
