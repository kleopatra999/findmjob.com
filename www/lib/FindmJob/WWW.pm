package FindmJob::WWW;

use Dancer ':syntax';

our $VERSION = '0.1';

use FindmJob::Basic;

# different template dir than default one
setting 'views'  => path( FindmJob::Basic->root, 'templates' );
setting 'public' => path( FindmJob::Basic->root, 'static' );

hook before_template_render => sub {
    my $tokens = shift;

    # merge vars into token b/c I like it more
    my $vars = delete $tokens->{vars} || {};
    foreach (keys %$vars) {
        $tokens->{$_} = $vars->{$_};
    }

    $tokens->{config} = FindmJob::Basic->config;
};

get '/' => sub {
    my $schema = FindmJob::Basic->schema;
    my @jobs = $schema->resultset('Job')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => 12
    })->all;
    var jobs => \@jobs;

    template 'index.tt2';
};

get '/job/:jobid' => sub {
    my $jobid = params->{jobid};
    my $schema = FindmJob::Basic->schema;
    my $job = $schema->resultset('Job')->find($jobid);
    var job => $job;

    template 'job.tt2';
};

get '/company/:companyid' => sub {
    my $companyid = params->{companyid};
    my $schema = FindmJob::Basic->schema;
    my $company = $schema->resultset('Company')->find($companyid);
    var company => $company;
    my @jobs    = $schema->resultset('Job')->search( {
        company_id => $companyid
    }, {
        order_by => 'inserted_at DESC',
        rows => 12
    })->all;
    var jobs => \@jobs;

    template 'company.tt2';
};

true;
