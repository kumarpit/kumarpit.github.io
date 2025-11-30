// Theme toggle functionality
(function() {
  const root = document.documentElement;
  const themeToggle = document.getElementById('theme-toggle');

  // Check for saved theme preference or default to system preference
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme) {
    root.setAttribute('data-theme', savedTheme);
  }

  // Update button icon
  function updateButton() {
    const currentTheme = root.getAttribute('data-theme');
    const isDark = currentTheme === 'dark' ||
                   (!currentTheme && window.matchMedia('(prefers-color-scheme: dark)').matches);
    themeToggle.innerHTML = isDark ? '<i class="fa-solid fa-sun"></i>' : '<i class="fa-solid fa-moon"></i>';
  }

  // Toggle theme
  themeToggle.addEventListener('click', function() {
    const currentTheme = root.getAttribute('data-theme');
    const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

    let newTheme;
    if (!currentTheme) {
      // If no manual theme set, toggle from system preference
      newTheme = systemPrefersDark ? 'light' : 'dark';
    } else if (currentTheme === 'dark') {
      newTheme = 'light';
    } else {
      newTheme = 'dark';
    }

    root.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    updateButton();
  });

  updateButton();
})();
