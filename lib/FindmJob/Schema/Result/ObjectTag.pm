use utf8;
package FindmJob::Schema::Result::ObjectTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::ObjectTag

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<object_tag>

=cut

__PACKAGE__->table("object_tag");

=head1 ACCESSORS

=head2 object

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 tag

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 time

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "object",
  { data_type => "char", is_nullable => 0, size => 22 },
  "tag",
  { data_type => "char", is_nullable => 0, size => 22 },
  "time",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</object>

=item * L</tag>

=back

=cut

__PACKAGE__->set_primary_key("object", "tag");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-08-15 18:56:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IBT6fRtBI7804IWTQCj2lw

__PACKAGE__->belongs_to(
    tag => 'Tag',
    { 'foreign.id' => 'self.tag' }
);
__PACKAGE__->belongs_to(
    object => 'Object',
    { 'foreign.id' => 'self.object' }
);

1;
