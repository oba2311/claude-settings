---
name: Supabase + PostHog stack setup
description: Standard workflow for wiring up Supabase and PostHog in new projects — this is the user's default stack for any new app
type: reference
---

## Stack defaults
- **Database/backend:** Supabase (project at kmkapfotqjdmgzzibrkw for recipes, but each new project gets its own)
- **Analytics:** PostHog EU region (`https://eu.i.posthog.com`)

---

## Supabase setup

1. Create project at supabase.com
2. Run schema SQL in the SQL editor (REST API can't do DDL)
3. Enable RLS + public read policy:
   ```sql
   alter table your_table enable row level security;
   create policy "Public read" on your_table for select using (true);
   ```
4. Two keys needed:
   - **Anon key** (`sb_publishable_...`) → safe to ship in frontend
   - **Service role key** (`eyJ...`) → server/CLI only, never in frontend

### Connection from external tools (e.g. PostHog data warehouse)
- Direct connection (port 5432) is **IPv4-incompatible** on free plan
- Use **Session Pooler** instead:
  - Host: `aws-0-eu-central-1.pooler.supabase.com` (get from Supabase → Connect → Session pooler)
  - Port: `6543`
  - User: `postgres.<project-ref>` (note the project ref prefix)
  - Password: your DB password

---

## PostHog setup (plain HTML / no framework)

Add to `<head>` — paste the snippet from PostHog → Manual SDK setup → Web:

```html
<script>
  !function(t,e){...minified loader...}(document,window.posthog||[]);
  posthog.init('phc_YOUR_KEY', {
    api_host: 'https://eu.i.posthog.com',
    defaults: '2026-01-30',
    person_profiles: 'identified_only',
  })
</script>
```

Add custom events wherever meaningful:
```javascript
// Example: track which recipes get opened
posthog.capture('recipe_viewed', { recipe_id: id, recipe_title: title });
```

### Supabase → PostHog data warehouse sync
Go to PostHog → Data pipelines → Sources → Supabase.
Enter Session Pooler credentials (see above). Syncs table data into PostHog for SQL querying alongside analytics.

---

## Testing PostHog events from terminal

Personal API key stored in `~/.zshrc` as `POSTHOG_API_KEY`.
API base: `https://eu.posthog.com`

```bash
# Get project ID (run once per project)
curl -s "https://eu.posthog.com/api/projects/@current/" \
  -H "Authorization: Bearer $POSTHOG_API_KEY" | python3 -c "
import json,sys; d=json.load(sys.stdin); print(d['id'], d['name'])"

# Check recent events
curl -s "https://eu.posthog.com/api/projects/{PROJECT_ID}/events/?limit=10" \
  -H "Authorization: Bearer $POSTHOG_API_KEY" | python3 -c "
import json,sys
for e in json.load(sys.stdin).get('results',[]):
    print(e['timestamp'][:19], e['event'], e.get('properties',{}).get('recipe_title',''))"
```

Known projects:
- **Recipes** → project ID `158954`

---

## For new projects: checklist

- [ ] Supabase: create project, run schema, set RLS
- [ ] Add `SUPABASE_URL` + `SUPABASE_SERVICE_KEY` to `~/.zshrc`
- [ ] Frontend: use anon key only
- [ ] PostHog: add HTML snippet to `<head>` (EU region)
- [ ] PostHog: add `posthog.capture()` for key user actions
- [ ] PostHog data warehouse: connect via Session Pooler (port 6543)
