begin;

grant execute on function app.extraction_job_result_payload(public.extraction_jobs) to authenticated, service_role;
grant execute on function app.extraction_job_worker_payload(public.extraction_jobs) to authenticated, service_role;

commit;
