﻿
# include <Siv3D.hpp>
# include "Test/Siv3DTest.hpp"
using namespace s3d;
using namespace s3d::literals;

void Main()
{
	Log << InfiniteList(0, 3).take(100).sum();

	RunTest();
}
