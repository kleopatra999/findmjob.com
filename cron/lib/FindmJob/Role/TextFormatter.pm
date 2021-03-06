package FindmJob::Role::TextFormatter;

use Moo::Role;
use FindmJob::HTML::FormatText;
use HTML::TreeBuilder;

has 'formatter' => (
    is => 'lazy',
);

sub _build_formatter {
    return FindmJob::HTML::FormatText->new(leftmargin => 0, rightmargin => 999);
}

sub format_tree_text {
    my ($self, $ele) = @_;

    return unless $ele;
    my $txt = $self->formatter->format($ele);

    my $x100 = '-' x 100;
    $txt =~ s/\-{80,}/$x100/sg;
    $txt =~ s/^\s+|\s+$//g;
    $txt =~ s/\n{3,}/\n\n/g;
    $txt =~ s/\xA0/ /g;

    return $txt;
}

sub format_text {
    my ($self, $text) = @_;

    return unless defined $text and length $text;

    my $tree = HTML::TreeBuilder->new_from_content($text);
    my $txt  = $self->format_tree_text($tree);
    $tree = $tree->delete;

    return $txt;
}

1;