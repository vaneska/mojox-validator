#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 64;

use_ok('MojoX::Validator::Field');

my $field = MojoX::Validator::Field->new(name => 'foo');
$field->required(1);
$field->length([3, 20]);
$field->regexp(qr/^\d+$/);

ok(!$field->is_valid);
is($field->error, 'REQUIRED');

$field->value('');
ok(!$field->is_valid);
is($field->error, 'REQUIRED');

$field->value('   ');
ok(!$field->is_valid);
is($field->error, 'REQUIRED');

$field->value('ab');
ok(!$field->is_valid);
is($field->error, 'LENGTH_CONSTRAINT_FAILED');

$field->value('abc');
ok(!$field->is_valid);
is($field->error, 'REGEXP_CONSTRAINT_FAILED');

$field->value(123);
ok($field->is_valid);
ok(!$field->error);

$field = MojoX::Validator::Field->new(name => 'foo');
$field->length([3, 20]);

ok($field->is_valid);
ok(!$field->error);

$field->value('ab');
ok(!$field->is_valid);
is($field->error, 'LENGTH_CONSTRAINT_FAILED');

$field->value('abc');
ok($field->is_valid);
ok(!$field->error);

$field = MojoX::Validator::Field->new(name => 'foo');
$field->length([3, 20]);

$field->value([qw/fo bar/]);
is($field->value, 'fo');
ok(!$field->is_valid);
is($field->error, 'LENGTH_CONSTRAINT_FAILED');

$field->value([qw/foo ba/]);
is($field->value, 'foo');
ok($field->is_valid);
ok(!$field->error);

$field->multiple(1);
$field->value([qw/foo ba/]);
is_deeply($field->value, [qw/foo ba/]);
ok(!$field->is_valid);

$field->value([qw/foo bar/]);
is_deeply($field->value, [qw/foo bar/]);
ok($field->is_valid);

$field = MojoX::Validator::Field->new(name => 'foo');
$field->required(1)->in(0, 1);
ok(!$field->is_defined);
ok($field->is_empty);
ok(!$field->is_valid);

$field->value(0);
ok($field->is_defined);
ok(!$field->is_empty);
ok($field->is_valid);

$field = MojoX::Validator::Field->new(name => 'foo');
$field->multiple(2, 3);
$field->value([qw/foo/]);
ok(!$field->is_valid);
is($field->error, 'NOT_ENOUGH');

$field->value([qw/foo bar/]);
ok($field->is_valid);

$field->value([qw/foo bar baz/]);
ok($field->is_valid);

$field->value([qw/foo bar baz urgh/]);
ok(!$field->is_valid);
is($field->error, 'TOO_MUCH');

$field = MojoX::Validator::Field->new(name => 'foo');
$field->multiple(2);
$field->value([qw/foo/]);
ok(!$field->is_valid);
is($field->error, 'NOT_ENOUGH');

$field->value([qw/foo bar/]);
ok($field->is_valid);

$field->value([qw/foo bar baz/]);
ok(!$field->is_valid);
is($field->error, 'TOO_MUCH');

# Custom error messages
$field = MojoX::Validator::Field->new(name => 'foo');
$field->length([3, 20]);
$field->message('Name can have between %s and %s characters, you entered %s!');

$field->value('Hi');
ok(!$field->is_valid);
is($field->error, 'Name can have between 3 and 20 characters, you entered 2!');

# inflate
$field = MojoX::Validator::Field->new(name => 'foo');
$field->inflate(sub { $_ = 'inflate' });
$field->value('raw');
ok($field->is_valid);
is($field->value, 'inflate');

$field->inflate(sub { s/bar/baz/; $_ });
$field->multiple(1);
$field->value([qw/foo bar/]);
ok($field->is_valid);
is_deeply($field->value, [qw/foo baz/]);

$field = MojoX::Validator::Field->new(name => 'foo');
$field->multiple(1);
$field->regexp(qr/^\d+$/);

$field->inflate(sub { split /:/ });
$field->value('10:20:30');
ok($field->is_valid);
is_deeply($field->value, [qw/10 20 30/]);

$field->inflate(sub { s/:/0/g; $_ });
$field->value('10:20:30');
ok($field->is_valid);
is_deeply($field->value, [qw/10020030/]);

# deflate
$field = MojoX::Validator::Field->new(name => 'foo');
$field->deflate(sub { $_ = 'deflate' });
$field->value('raw');
ok($field->is_valid);
is($field->value, 'deflate');

$field->deflate(sub { s/bar/baz/; $_ });
$field->multiple(1);
$field->value([qw/foo bar/]);
ok($field->is_valid);
is_deeply($field->value, [qw/foo baz/]);

$field->deflate(sub { split /:/ });
$field->multiple(1);
$field->value('10:20:30');
$field->regexp(qr/^[\d:]+$/);
ok($field->is_valid);
is_deeply($field->value, [qw/10 20 30/]);

# inflate/deflate
$field = MojoX::Validator::Field->new(name => 'foo');
$field->inflate(sub { s/bar/baz/; $_ });
$field->deflate(sub { s/baz/foo/; $_ });
$field->value('bar');
ok($field->is_valid);
is($field->value, 'foo');
