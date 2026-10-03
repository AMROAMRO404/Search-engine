// Shows or hides the extra values of a facet ("more..." / "less...").
function toggleFacet(link, id) {
    var extra = document.getElementById(id);
    var nowHidden = extra.classList.toggle('is-hidden');
    link.textContent = nowHidden ? 'more...' : 'less...';
    return false;
}
