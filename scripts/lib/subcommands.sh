#!/usr/bin/env bash
# Subcommand dispatch helpers for OllamaTrauma.

dispatch_subcommand() {
  if [[ -z "${SUBCOMMAND:-}" ]]; then
    return 0
  fi

  case "${SUBCOMMAND}" in
    show)
      if [[ -n "${CLI_MODEL:-}" ]]; then
        show_model "${CLI_MODEL}"
        exit 0
      else
        log_error "show requires --model <name>"
        usage
        exit 2
      fi
      ;;
    health)
      run_menu_action health_check_dashboard
      exit 0
      ;;
    run)
      if [[ -n "${CLI_MODEL:-}" ]]; then
        AUTO_MODE=1
        AUTO_MESSAGE=""
        AUTO_CHOICE=""
        chat_interface || main_menu
        exit 0
      else
        main_menu
        exit 0
      fi
      ;;
    download)
      if [[ -n "${CLI_BATCH:-}" ]]; then
        run_menu_action batch_download_models
        exit 0
      else
        downloads_menu
        exit 0
      fi
      ;;
    batch)
      run_menu_action batch_download_models
      exit 0
      ;;
  esac
}
