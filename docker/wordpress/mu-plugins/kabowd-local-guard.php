<?php
/**
 * Local-only safety rails for the Kabowd Docker environment.
 */

if (function_exists('wp_get_environment_type') && wp_get_environment_type() !== 'local') {
    return;
}

add_filter('pre_option_blog_public', '__return_zero');

add_action('send_headers', function () {
    header('X-Robots-Tag: noindex, nofollow', true);
});

add_action('phpmailer_init', function ($phpmailer) {
    $phpmailer->isSMTP();
    $phpmailer->Host = getenv('LOCAL_SMTP_HOST') ?: 'mailpit';
    $phpmailer->Port = (int) (getenv('LOCAL_SMTP_PORT') ?: 1025);
    $phpmailer->SMTPAuth = false;
    $phpmailer->SMTPSecure = false;
    $phpmailer->SMTPAutoTLS = false;
});

add_filter('pre_http_request', function ($preempt, $parsed_args, $url) {
    if ((getenv('LOCAL_BLOCK_EXTERNAL_HTTP') ?: 'false') !== 'true') {
        return $preempt;
    }

    $host = parse_url($url, PHP_URL_HOST);
    $allowed_hosts = array(
        'api.wordpress.org',
        'downloads.wordpress.org',
        'downloads.w.org',
        'wordpress.org',
        's.w.org',
    );

    if ($host && in_array($host, $allowed_hosts, true)) {
        return $preempt;
    }

    return new WP_Error(
        'kabowd_local_external_http_blocked',
        sprintf('External HTTP request blocked in local Docker: %s', $url)
    );
}, 10, 3);

add_action('admin_bar_menu', function ($admin_bar) {
    if (! is_admin_bar_showing()) {
        return;
    }

    $admin_bar->add_node(array(
        'id' => 'kabowd-local-env',
        'title' => 'LOCAL',
        'href' => home_url('/'),
    ));
}, 100);
