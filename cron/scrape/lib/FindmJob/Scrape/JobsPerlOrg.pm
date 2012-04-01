package FindmJob::Scrape::JobsPerlOrg;

use Moose;
with 'FindmJob::Scrape::Role';

use XML::Simple 'XMLin';
use HTML::TreeBuilder;
use Try::Tiny;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');
    my $resp = $self->get('http://jobs.perl.org/rss/standard.rss');
    my $data = XMLin($resp->decoded_content);
    foreach my $item ( @{$data->{item}} ) {
        my $link = $item->{link};
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted;
        $self->on_single_page($item);
    }
}

sub on_single_page {
    my ($self, $item) = @_;

    my $link = $item->{link};
    my $resp = $self->get($link);
    my $tree = HTML::TreeBuilder->new_from_content($resp->decoded_content);
 #   try {
        my $data;
        my $title = $tree->look_down(_tag => 'h1')->as_trimmed_text;
        my @trs = $tree->look_down(_tag => 'tr', sub { $_[0]->look_down(_tag => 'a', sub { defined($_[0]->attr('name')) }) });
        foreach my $tr (@trs) {
            my @tds = $tr->look_down(_tag => 'td');
            next if @tds > 2;
            my $k   = $tr->look_down(_tag => 'a')->attr('name');
            my $v   = $tds[1]->as_trimmed_text;
            $v =~ s/\xA0/ /g;
            $data->{$k} = $v;
        }

        # insert

        use Data::Dumper;
        my $row = {
            source_url => $link,
            title => $title,
            company => {
                name => delete $data->{company_name},
                website => delete $data->{website},
                contact => delete $data->{contact},
            },
            description => delete $data->{description},
            location => delete $data->{location},
            extra => Dumper(\$data),
        };
        $self->schema->resultset('Job')->create_job($row);
#    } catch {
#        $self->log_fatal($_);
#    }
    $tree = $tree->delete;

    exit;
}

1;