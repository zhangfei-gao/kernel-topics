// SPDX-License-Identifier: GPL-2.0
/*
 * Minimal test driver to verify llcc_slice_getd()/activate() works.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/soc/qcom/llcc-qcom.h>

static const u32 llcc_test_uids[] = {
	LLCC_CPUSS, LLCC_CMPT, LLCC_GPUHTW, LLCC_GPU, LLCC_MMUHWT,
	LLCC_CAMFW, LLCC_ECC, LLCC_WRCACHE, LLCC_LCPDARE, LLCC_COMPUTE1,
	LLCC_PCIE_TCU,
};

static int llcc_test_probe(struct platform_device *pdev)
{
	struct llcc_slice_desc *desc;
	int ret, i;

	for (i = 0; i < ARRAY_SIZE(llcc_test_uids); i++) {
		u32 uid = llcc_test_uids[i];

		desc = llcc_slice_getd(uid);
		if (IS_ERR(desc)) {
			dev_err(&pdev->dev, "gzf llcc_test: uid=%u getd failed: %ld\n",
				uid, PTR_ERR(desc));
			continue;
		}

		dev_info(&pdev->dev, "gzf llcc_test: uid=%u getd OK, slice_id=%d size=%zu\n",
			 uid, llcc_get_slice_id(desc), llcc_get_slice_size(desc));

		ret = llcc_slice_activate(desc);
		dev_info(&pdev->dev, "gzf llcc_test: uid=%u activate ret=%d\n", uid, ret);

		llcc_slice_putd(desc);
	}

	/* Negative test: LLCC_AUDIO has no slice configured on Nord */
	desc = llcc_slice_getd(LLCC_AUDIO);
	dev_info(&pdev->dev, "gzf llcc_test: uid=%u (unconfigured) getd=%s\n",
		 LLCC_AUDIO, IS_ERR(desc) ? "FAIL (expected)" : "OK (unexpected!)");

	return 0;
}

static const struct of_device_id llcc_test_of_match[] = {
	{ .compatible = "qcom,llcc-test" },
	{ }
};
MODULE_DEVICE_TABLE(of, llcc_test_of_match);

static struct platform_driver llcc_test_driver = {
	.probe = llcc_test_probe,
	.driver = {
		.name = "qcom-llcc-test",
		.of_match_table = llcc_test_of_match,
	},
};
module_platform_driver(llcc_test_driver);

MODULE_DESCRIPTION("Qualcomm LLCC test driver");
MODULE_LICENSE("GPL");
