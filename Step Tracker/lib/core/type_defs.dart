import 'package:stride_ai/core/failures/failure.dart';

typedef FutureEither<T> = Future<T>;
// Using simple Futures for now to avoid introducing Either (fpdart/dartz) unless requested, 
// keeping it clean and minimal. We will throw Exceptions and catch them, returning null or defaulting.
