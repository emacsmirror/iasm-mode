(progn
  (setq debug-on-error t)
  (load-file "~/code/iasm-mode/iasm-mode.el")
  (iasm-disasm "~/code/lockless/bin/tls_perf_test"))

(progn
  (setq debug-on-error t)
  (load-file "~/code/iasm-mode/iasm-mode.el")
  (iasm-ldd "~/code/lockless/bin/tls_perf_test"))

