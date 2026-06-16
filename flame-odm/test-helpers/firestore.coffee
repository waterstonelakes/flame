# Firestore-backed (e2e) tests need real credentials, which aren't available on
# every machine (e.g. a devbox). `hasCredentials` lets a suite skip itself when
# they're absent so the unit suite stays green; with FB_SERVICE_ACCOUNT set to a
# service-account JSON string (the 'process-env' Adapter mode) the e2e suites run
# in full.
hasCredentials = -> !!(process.env.FB_SERVICE_ACCOUNT)

module.exports = { hasCredentials }
