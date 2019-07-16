SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'siapnet'
	AND pid <> pg_backend_pid()
	AND state in ('idle', 'idle in transaction', 'idle in transaction (aborted)', 'disabled') 
	AND state_change < current_timestamp - INTERVAL '1' MINUTE;
	
	
	SELECT 
    pg_terminate_backend(pid) 
FROM 
    pg_stat_activity 
WHERE 
    -- don't kill my own connection!
    pid <> pg_backend_pid()
    -- don't kill the connections to other databases
AND datname = 'siapnet';

	
