// Shared AJAX search: runs in the background (the old synchronous requests froze the
// page while typing), drops responses from searches that have been superseded, dims
// the old results while waiting and fades the new ones in.
const pending = {};

export function searchInto(target, { url, data }, onLoaded) {
  const $target = $(target);

  if (pending[target]) pending[target].abort();
  $target.addClass("is-loading").attr("aria-busy", true);

  pending[target] = $.ajax({ url, data, type: "get" })
    .done(html => {
      $target.html(html);
      $target.children().addClass("fade-in-up");
      if (onLoaded) onLoaded();
    })
    .fail((_xhr, status) => {
      if (status !== "abort") alert("Search could not be completed.");
    })
    .always((_data, status) => {
      if (status === "abort") return;
      pending[target] = null;
      $target.removeClass("is-loading").removeAttr("aria-busy");
    });
}
