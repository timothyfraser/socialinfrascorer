# A fake HTTP backend: records every request and answers with a canned reply.
fake_backend = function(status = 200L, body = "[]") {
  calls = list()
  fn = function(req) {
    calls[[length(calls) + 1]] <<- req
    list(status = status, body = body)
  }
  list(fn = fn, calls = function() calls)
}

fake_client = function(access_token = NULL) {
  client(
    supabase_url = "https://example.supabase.co/",
    anon_key = "anon-key",
    access_token = access_token
  )
}
