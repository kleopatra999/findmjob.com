use utf8;
package FindmJob::Schema::Result::ObjectTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::ObjectTag

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<object_tag>

=cut

__PACKAGE__->table("object_tag");

=head1 ACCESSORS

=head2 object

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 tag

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 time

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "object",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "tag",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07019 @ 2012-03-31 23:20:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IO4IeuLlyMjcnbLf4iR5oQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;