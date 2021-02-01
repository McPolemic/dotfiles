module.exports = {
  defaultBrowser: "Safari",
  rewrite: [
    {
      // Always open Amazon in Smile-mode (for donations)
      match: finicky.matchDomains("www.amazon.com"),
      url: ({url}) => ({
        ...url,
        host: "smile.amazon.com"
      })
    }
  ],
  handlers: [
    {
      // Open Google Meet in Chrome (so an extension can save transcripts)
      match: finicky.matchDomains("meet.google.com"),
      browser: "Google Chrome"
    },
    {
      // Open Spotify URLs in Spotify
      match: finicky.matchDomains("open.spotify.com"),
      browser: "Spotify"
    }
  ]
}
