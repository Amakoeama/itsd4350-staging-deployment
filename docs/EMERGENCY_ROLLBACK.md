# Emergency Rollback Procedure

## Purpose
Restore the previously healthy Blue production environment if
the Green deployment fails after promotion.

## Emergency steps
1. Open WSL Ubuntu and navigate to the project repository.
2. Confirm Docker and the NGINX container are running.
3. Execute: bash scripts/blue-green/rollback.sh
4. Enter ROLLBACK when prompted.
5. Verify: curl -sS http://localhost:8080/health
6. Confirm production-blue, healthy, and version 1.0.
7. Review NGINX configuration if verification fails:
   docker exec itsd4350-nginx nginx -t

## Important
Rollback relies on the previous routing configuration
preserved during promotion. Do not delete the backup
before rollback.

If automated rollback fails, stop further promotions,
retain logs, and investigate the routing configuration
before attempting manual recovery.
